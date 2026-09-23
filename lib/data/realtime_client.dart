import 'dart:async';

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
class RealtimeClient extends ChangeNotifier {
  RealtimeClient._();
  static final RealtimeClient instance = RealtimeClient._();

  io.Socket? _socket;
  Timer? _queueRefreshDebounce;
  final Set<String> _pendingQueueTables = {};
  Future<void> Function()? queueRefreshHook;

  static const queueTables = {
    'appointments',
    'queue_entries',
    'walk_in_appointments',
    'doctor_appointment_state',
  };

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
          .enableReconnection()
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('Realtime connected');
      notifyListeners();
      unawaited(queueRefreshHook?.call() ?? Future<void>.value());
    });
    socket.onDisconnect((_) {
      debugPrint('Realtime disconnected');
      notifyListeners();
    });
    socket.onConnectError((e) {
      debugPrint('Realtime connect error: $e');
      notifyListeners();
    });

    socket.on('data:changed', (payload) {
      if (payload is Map && payload['table'] is String) {
        final table = payload['table'] as String;
        // Queue tables arrive together through queue:changed so all role-based
        // queue views are refreshed as one coherent snapshot.
        if (queueTables.contains(table)) return;
        // Fire and forget: refresh just the changed table.
        DatabaseSync.instance.refreshTable(table);
      }
    });

    socket.on('queue:changed', (payload) {
      final tables =
          (payload is Map && payload['tables'] is List
                  ? (payload['tables'] as List).whereType<String>()
                  : queueTables)
              .toSet();
      _scheduleQueueRefresh(tables);
    });

    socket.connect();
    _socket = socket;
  }

  void _scheduleQueueRefresh(
    Iterable<String> tables, {
    Duration delay = const Duration(milliseconds: 150),
  }) {
    _pendingQueueTables.addAll(tables);
    _queueRefreshDebounce?.cancel();
    _queueRefreshDebounce = Timer(delay, () async {
      // Do not lose a socket event merely because a normal sync is in flight.
      if (DatabaseSync.instance.busy) {
        _scheduleQueueRefresh(
          const [],
          delay: const Duration(milliseconds: 300),
        );
        return;
      }
      final requested = Set<String>.from(_pendingQueueTables);
      _pendingQueueTables.clear();
      await DatabaseSync.instance.refreshTables(requested);
      await queueRefreshHook?.call();
    });
  }

  void disconnect() {
    _queueRefreshDebounce?.cancel();
    _queueRefreshDebounce = null;
    _pendingQueueTables.clear();
    _socket?.dispose();
    _socket = null;
    notifyListeners();
  }
}
