const assert = require('node:assert/strict');
const test = require('node:test');

const { runAppointmentReminders } = require('../src/appointmentReminders');

function fakeDatabase({ claimed = true } = {}) {
  const state = { notifications: [], transactions: [] };
  const client = {
    async query(sql, params) {
      state.transactions.push(sql);
      if (sql.includes('INSERT INTO appointment_reminders')) {
        return { rowCount: claimed ? 1 : 0, rows: [] };
      }
      if (sql.includes('INSERT INTO owner_notifications')) {
        state.notifications.push(params[2].value);
      }
      return { rowCount: 1, rows: [] };
    },
    release() {},
  };
  return {
    state,
    async query(sql, params) {
      state.candidateSql = sql;
      state.candidateParams = params;
      return {
        rows: [
          {
            id: 'appointment-row-1',
            owner_id: 'owner-1',
            start_at: new Date('2026-09-24T03:00:00.000Z'),
            appointment: {
              id: 'APT-1',
              pet: { name: 'Milo' },
              time: '10:00 AM',
            },
          },
        ],
      };
    },
    async connect() {
      return client;
    },
  };
}

test('sends one appointment push and stores it in the owner feed', async () => {
  const database = fakeDatabase();
  const pushes = [];
  const broadcasts = [];

  const result = await runAppointmentReminders(
    database,
    new Date('2026-09-24T02:30:00.000Z'),
    {
      sendPush: async (_database, ownerId, message) => {
        pushes.push({ ownerId, message });
      },
      broadcast: (table, scope) => broadcasts.push({ table, scope }),
    },
  );

  assert.deepEqual(result, { checked: 1, sent: 1 });
  assert.equal(database.state.candidateParams[1], 'Asia/Bangkok');
  assert.match(database.state.candidateSql, /INTERVAL '30 minutes'/);
  assert.match(database.state.candidateSql, /jsonb_extract_path_text/);
  assert.doesNotMatch(database.state.candidateSql, /->/);
  assert.equal(database.state.notifications.length, 1);
  assert.equal(database.state.notifications[0].title, 'Appointment in 30 minutes');
  assert.match(database.state.notifications[0].message, /Milo.*10:00 AM/);
  assert.equal(pushes.length, 1);
  assert.equal(pushes[0].ownerId, 'owner-1');
  assert.equal(pushes[0].message.data.appointmentId, 'APT-1');
  assert.deepEqual(broadcasts, [
    { table: 'owner_notifications', scope: { ownerId: 'owner-1' } },
  ]);
});

test('does not send a duplicate when the reminder is already claimed', async () => {
  const database = fakeDatabase({ claimed: false });
  let pushCount = 0;

  const result = await runAppointmentReminders(
    database,
    new Date('2026-09-24T02:30:00.000Z'),
    {
      sendPush: async () => pushCount++,
      broadcast: () => {},
    },
  );

  assert.deepEqual(result, { checked: 1, sent: 0 });
  assert.equal(pushCount, 0);
  assert.equal(database.state.notifications.length, 0);
});
