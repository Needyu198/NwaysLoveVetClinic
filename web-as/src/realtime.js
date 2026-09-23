// Socket.io client for live updates, mirroring the Flutter realtime client.
// Connects using the stored session token and invokes a callback when the
// backend broadcasts that a table changed.

import { io } from 'socket.io-client';
import { baseUrl, getToken } from './api.js';

let socket = null;
const QUEUE_TABLES = new Set([
  'appointments',
  'queue_entries',
  'walk_in_appointments',
  'doctor_appointment_state',
]);

export function connectRealtime(onTableChanged, onConnectionChanged = () => {}) {
  const token = getToken();
  if (!token) return () => {};
  if (socket) socket.disconnect();

  socket = io(baseUrl(), {
    transports: ['websocket'],
    auth: { token },
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 500,
    reconnectionDelayMax: 5000,
  });

  socket.on('connect', () => onConnectionChanged(true));
  socket.on('disconnect', () => onConnectionChanged(false));
  socket.on('connect_error', () => onConnectionChanged(false));

  socket.on('data:changed', payload => {
    if (payload && typeof payload.table === 'string') {
      // Queue writes emit several table events in one transaction. The
      // queue-domain event below coalesces them into a single UI reload.
      if (QUEUE_TABLES.has(payload.table)) return;
      onTableChanged(payload.table);
    }
  });

  let queueTimer = null;
  socket.on('queue:changed', () => {
    window.clearTimeout(queueTimer);
    queueTimer = window.setTimeout(() => onTableChanged('queue_entries'), 150);
  });

  return () => {
    window.clearTimeout(queueTimer);
    onConnectionChanged(false);
    socket?.disconnect();
    socket = null;
  };
}
