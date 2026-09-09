// Socket.io client for live updates, mirroring the Flutter realtime client.
// Connects using the stored session token and invokes a callback when the
// backend broadcasts that a table changed.

import { io } from 'socket.io-client';
import { baseUrl, getToken } from './api.js';

let socket = null;

export function connectRealtime(onTableChanged) {
  const token = getToken();
  if (!token) return () => {};
  if (socket) socket.disconnect();

  socket = io(baseUrl(), {
    transports: ['websocket'],
    auth: { token },
  });

  socket.on('data:changed', payload => {
    if (payload && typeof payload.table === 'string') {
      onTableChanged(payload.table);
    }
  });

  return () => {
    socket?.disconnect();
    socket = null;
  };
}
