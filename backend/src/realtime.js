// Real-time layer using Socket.io.
//
// After any successful /data/:table/sync commit, the API calls broadcastChange()
// to notify connected clients that a table changed. Clients (Flutter and the
// React staff app) listen for "data:changed" and refresh the affected table,
// giving a live queue and live updates across all synced tables.
//
// Auth: a client passes its session token in the Socket.io handshake auth. We
// validate it against app_sessions (same scheme as the REST middleware) so only
// authenticated sessions receive events. Clients join a room per role so we can
// scope broadcasts if needed later.

const crypto = require('node:crypto');
const { Server } = require('socket.io');

const hash = token => crypto.createHash('sha256').update(token).digest('hex');

let io = null;

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
  io.emit('data:changed', { table, at: Date.now(), ...meta });
}

module.exports = { attachRealtime, broadcastChange };
