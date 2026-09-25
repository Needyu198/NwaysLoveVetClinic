// Real-time layer using Socket.io.
//
// After any successful /data/:table/sync commit, the API calls broadcastChange()
// to notify connected clients that a table changed. Clients (Flutter and the
// React staff app) listen for "data:changed" and the queue-specific
// "queue:changed" domain event, giving every queue screen one coherent refresh.
//
// Auth: a client passes its session token in the Socket.io handshake auth. We
// validate it against app_sessions (same scheme as the REST middleware) so only
// authenticated sessions receive events. Owner-specific changes go only to the
// affected account plus clinic roles; clinic-wide changes go to all clients.

const crypto = require('node:crypto');
const { Server } = require('socket.io');

const hash = token => crypto.createHash('sha256').update(token).digest('hex');

let io = null;
const queueTables = Object.freeze([
  'appointments',
  'pet_care_bookings',
  'queue_entries',
  'walk_in_appointments',
  'doctor_appointment_state',
]);

/**
 * Attach Socket.io to the given HTTP server.
 * @param {import('http').Server} httpServer
 * @param {import('pg').Pool} pool
 */
function attachRealtime(httpServer, pool) {
  io = new Server(httpServer, {
    // Allow the Flutter app and the React dev server to connect.
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token || typeof token !== 'string') {
        return next(new Error('unauthorized'));
      }
      const session = (
        await pool.query(
          'SELECT s.account_id, s.role FROM app_sessions s JOIN app_accounts a ON a.id=s.account_id AND a.active AND a.role=s.role WHERE s.token_hash=$1 AND s.expires_at>NOW()',
          [hash(token)],
        )
      ).rows[0];
      if (!session) return next(new Error('unauthorized'));
      socket.data.accountId = session.account_id;
      socket.data.role = session.role;
      next();
    } catch (e) {
      next(new Error('unavailable'));
    }
  });

  io.on('connection', socket => {
    socket.join(`role:${socket.data.role}`);
    socket.join(`account:${socket.data.accountId}`);
  });

  return io;
}

/**
 * Notify clients that a table changed so they can refresh it.
 * Safe to call even if realtime is not attached (no-op).
 * @param {string} table
 * @param {{ ownerId?: string }} [meta]
 */
function broadcastChange(table, meta = {}) {
  if (!io) return;
  const audience = meta.ownerId
    ? io
        .to(`account:${meta.ownerId}`)
        .to('role:staff')
        .to('role:doctor')
        .to('role:systemAdmin')
    : io;
  audience.emit('data:changed', { table, at: Date.now(), ...meta });
  if (queueTables.includes(table)) {
    // Queue screens use different tables depending on the signed-in role.
    // One domain event lets every path refresh its permitted queue snapshot.
    audience.emit('queue:changed', {
      sourceTable: table,
      tables: queueTables,
      at: Date.now(),
      ...meta,
    });
  }
}

module.exports = { attachRealtime, broadcastChange, queueTables };
