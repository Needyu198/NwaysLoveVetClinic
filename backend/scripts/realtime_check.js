// Live check for the Socket.io real-time layer.
// Logs in, connects a socket with the session token, subscribes to
// data:changed, then performs a queue_entries sync and asserts the event fires.
const { io } = require('socket.io-client');

const BASE = process.env.BASE || 'http://127.0.0.1:5050';

async function api(method, path, token, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: await res.json().catch(() => ({})) };
}

(async () => {
  // Use the staff account (queue_entries is owner-scoped; petOwner can write its own)
  const login = await api('POST', '/auth/login', null, {
    username: 'petowner',
    password: 'Owner@123',
  });
  const token = login.body.token;
  if (!token) {
    console.error('FAIL: could not log in');
    process.exit(1);
  }

  // 1) Reject bad token on handshake
  const badResult = await new Promise(resolve => {
    const s = io(BASE, { transports: ['websocket'], auth: { token: 'nope' } });
    s.on('connect', () => { s.close(); resolve('connected'); });
    s.on('connect_error', () => { s.close(); resolve('rejected'); });
    setTimeout(() => { s.close(); resolve('timeout'); }, 4000);
  });
  console.log(`handshake bad token -> ${badResult} (${badResult === 'rejected' ? 'ok' : 'FAIL'})`);

  // 2) Accept good token and receive event on sync
  const rid = `rt-${Date.now()}`;
  const got = await new Promise(resolve => {
    const s = io(BASE, { transports: ['websocket'], auth: { token } });
    let done = false;
    const finish = v => { if (!done) { done = true; s.close(); resolve(v); } };
    s.on('connect', async () => {
      // trigger a change after we are connected
      await api('POST', '/data/queue_entries/sync', token, {
        changes: [{ id: rid, version: 0, data: { key: rid, value: { note: 'rt test' } } }],
        deletions: [],
      });
    });
    s.on('data:changed', payload => {
      if (payload && payload.table === 'queue_entries') finish('event');
    });
    s.on('connect_error', e => finish(`connect_error:${e.message}`));
    setTimeout(() => finish('timeout'), 6000);
  });
  console.log(`good token receives data:changed -> ${got} (${got === 'event' ? 'ok' : 'FAIL'})`);

  // cleanup the temp record (version is 1 after create)
  await api('POST', '/data/queue_entries/sync', token, {
    changes: [],
    deletions: [{ id: rid, version: 1 }],
  });

  const ok = badResult === 'rejected' && got === 'event';
  console.log(ok ? 'REALTIME OK' : 'REALTIME FAIL');
  process.exit(ok ? 0 : 1);
})();
