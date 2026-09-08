import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'clinic_api.dart';
import 'database_sync.dart';

/// Connects to the backend Socket.io server and refreshes affected tables live
/// when the server broadcasts a `data:changed` event. This is what makes the
/// patient queue (and every other synced table) update in real time.
///
/// Degrades gracefully: if the socket cannot connect, the app keeps working via
/// normal sync/refresh; realtime just won't be active.
class RealtimeClient {
  RealtimeClient._();
  static final RealtimeClient instance = RealtimeClient._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Open a realtime connection using the current session token. Call this
  /// after a successful login (when [ClinicApi.instance.token] is set).
  void connect() {
    final token = ClinicApi.instance.token;
    if (token == null) return;
    // Reuse an existing connection if already up.
    if (_socket != null) {
      disconnect();
    }

    final socket = io.io(
      ClinicApi.instance.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) => debugPrint('Realtime connected'));
    socket.onDisconnect((_) => debugPrint('Realtime disconnected'));
    socket.onConnectError((e) => debugPrint('Realtime connect error: $e'));

    socket.on('data:changed', (payload) {
      if (payload is Map && payload['table'] is String) {
        // Fire and forget: refresh just the changed table.
        DatabaseSync.instance.refreshTable(payload['table'] as String);
      }
    });

    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
