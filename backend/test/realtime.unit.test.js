const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const http = require('node:http');
const test = require('node:test');
const { io: connect } = require('socket.io-client');

const { attachRealtime, broadcastChange } = require('../src/realtime');

const hash = token => crypto.createHash('sha256').update(token).digest('hex');

const sessions = new Map([
  [hash('owner-a-token'), { account_id: 'owner-a', role: 'petOwner' }],
  [hash('owner-b-token'), { account_id: 'owner-b', role: 'petOwner' }],
  [hash('staff-token'), { account_id: 'staff-a', role: 'staff' }],
]);

const pool = {
  async query(_sql, parameters) {
    const session = sessions.get(parameters[0]);
    return { rows: session ? [session] : [] };
  },
};

function waitFor(socket, event, timeout = 1500) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${event}`)), timeout);
    socket.once(event, payload => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

function expectNoEvent(socket, event, timeout = 250) {
  return new Promise((resolve, reject) => {
    const listener = payload => reject(new Error(`Unexpected ${event}: ${JSON.stringify(payload)}`));
    socket.once(event, listener);
    setTimeout(() => {
      socket.off(event, listener);
      resolve();
    }, timeout);
  });
}

test('Socket.IO authenticates WebSockets and scopes queue events', async t => {
  const server = http.createServer();
  const realtime = attachRealtime(server, pool);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = `http://127.0.0.1:${server.address().port}`;
  const sockets = [];
  t.after(async () => {
    for (const socket of sockets) socket.close();
    await new Promise(resolve => realtime.close(resolve));
  });

  const bad = connect(url, {
    transports: ['websocket'],
    auth: { token: 'invalid-token' },
    reconnection: false,
  });
  sockets.push(bad);
  const badError = await waitFor(bad, 'connect_error');
  assert.equal(badError.message, 'unauthorized');

  const makeClient = token => {
    const socket = connect(url, {
      transports: ['websocket'],
      auth: { token },
      reconnection: false,
    });
    sockets.push(socket);
    return socket;
  };
  const ownerA = makeClient('owner-a-token');
  const ownerB = makeClient('owner-b-token');
  const staff = makeClient('staff-token');
  await Promise.all([
    waitFor(ownerA, 'connect'),
    waitFor(ownerB, 'connect'),
    waitFor(staff, 'connect'),
  ]);

  const ownerEvent = waitFor(ownerA, 'queue:changed');
  const staffEvent = waitFor(staff, 'queue:changed');
  const otherOwnerHasNoEvent = expectNoEvent(ownerB, 'queue:changed');
  broadcastChange('queue_entries', { ownerId: 'owner-a' });

  const [ownerPayload, staffPayload] = await Promise.all([
    ownerEvent,
    staffEvent,
    otherOwnerHasNoEvent,
  ]);
  assert.equal(ownerPayload.sourceTable, 'queue_entries');
  assert.equal(ownerPayload.ownerId, 'owner-a');
  assert.deepEqual(staffPayload.tables, [
    'appointments',
    'pet_care_bookings',
    'queue_entries',
    'walk_in_appointments',
    'doctor_appointment_state',
  ]);
});
