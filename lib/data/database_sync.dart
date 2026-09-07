import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'clinic_api.dart';
export 'database_icons.dart';

typedef DatabaseRows = Map<String, Map<String, dynamic>>;

/// Persists only changed records, with optimistic versions and ownership enforced
/// by the API. Listeners are disabled during hydration and outside a session.
class DatabaseSync extends ChangeNotifier {
  DatabaseSync._();
  static final instance = DatabaseSync._();
  final List<_Binding> _bindings = [];
  bool active = false;
  bool busy = false;
  String? error;
  Timer? _timer;
  Future<void>? _inFlight;
  bool get pending => _bindings.any((b) => b.dirty);

  void bind(
    String table,
    ChangeNotifier store,
    DatabaseRows Function() read,
    void Function(DatabaseRows) restore,
  ) {
    final binding = _Binding(table, read, restore, store);
    _bindings.add(binding);
    store.addListener(() {
      if (!active || busy || !binding.allowed) return;
      binding.dirty = true;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 300), () => flush());
      notifyListeners();
    });
  }

  Future<void> start() async {
    active = false;
    error = null;
    busy = true;
    try {
      for (final b in _bindings) {
        b.reset();
        b.restore({});
      }
      // Load in dependency order: bookings precede queue entries.
      for (final b in _bindings) {
        try {
          final result = await ClinicApi.instance.request(
            'GET',
            '/data/${b.table}',
          );
          b.allowed = true;
          b.hydrate(result['records'] as List);
        } on ClinicApiException catch (e) {
          if (e.statusCode != 403) rethrow;
        }
      }
      active = true;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      for (final b in _bindings) {
        b.store.notifyListeners();
      }
      busy = false;
      notifyListeners();
    }
  }

  Future<void> flush() {
    _timer?.cancel();
    if (_inFlight != null) return _inFlight!;
    final future = _flush();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _flush() async {
    if (!active || busy) return;
    error = null;
    try {
      for (final b in _bindings) {
        if (!b.allowed || !b.dirty) continue;
        final next = b.read();
        final changes = <Map<String, dynamic>>[];
        final deletions = <Map<String, dynamic>>[];
        for (final entry in next.entries) {
          if (jsonEncode(entry.value) == jsonEncode(b.baseline[entry.key])) {
            continue;
          }
          changes.add({
            'id':
                b.ids[entry.key] ??
                '${ClinicApi.instance.accountId}:${entry.key}',
            'version': b.versions[entry.key] ?? 0,
            if (_ownersByKey[entry.key] != null)
              'ownerId': _ownersByKey[entry.key],
            'data': {'key': entry.key, 'value': entry.value},
          });
        }
        for (final key in b.baseline.keys) {
          if (!next.containsKey(key) && b.ids.containsKey(key)) {
            deletions.add({'id': b.ids[key], 'version': b.versions[key]});
          }
        }
        if (changes.isNotEmpty || deletions.isNotEmpty) {
          final result = await ClinicApi.instance.request(
            'POST',
            '/data/${b.table}/sync',
            {'changes': changes, 'deletions': deletions},
          );
          for (final record in result['records'] as List) {
            final key = record['data']['key'] as String;
            b.ids[key] = record['id'] as String;
            b.versions[key] = record['version'] as int;
          }
          for (final item in deletions) {
            final keys = b.ids.keys
                .where((k) => b.ids[k] == item['id'])
                .toList();
            for (final key in keys) {
              b.ids.remove(key);
              b.versions.remove(key);
            }
          }
        }
        b.baseline = _copy(next);
        b.dirty = jsonEncode(b.read()) != jsonEncode(next);
      }
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
    if (error == null && pending) {
      _timer = Timer(const Duration(milliseconds: 300), () => flush());
    }
  }

  Future<void> refresh() async {
    await flush();
    if (error != null || pending) return;
    await start();
  }

  Future<void> stop() async {
    await flush();
    if (pending) {
      throw ClinicApiException(
        error ?? 'Changes are not saved yet. Retry before signing out.',
      );
    }
    active = false;
    _timer?.cancel();
    for (final b in _bindings) {
      b.reset();
      b.restore({});
      b.store.notifyListeners();
    }
    await ClinicApi.instance.logout();
    notifyListeners();
  }
}

DatabaseRows _copy(DatabaseRows value) =>
    (jsonDecode(jsonEncode(value)) as Map).map(
      (key, value) =>
          MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
    );

class _Binding {
  _Binding(this.table, this.read, this.restore, this.store);
  final String table;
  final DatabaseRows Function() read;
  final void Function(DatabaseRows) restore;
  final ChangeNotifier store;
  bool allowed = false;
  bool dirty = false;
  DatabaseRows baseline = {};
  final Map<String, String> ids = {};
  final Map<String, int> versions = {};
  void reset() {
    allowed = false;
    dirty = false;
    baseline = {};
    ids.clear();
    versions.clear();
  }

  void hydrate(List records) {
    final rows = <String, Map<String, dynamic>>{};
    for (final record in records) {
      final key = record['data']['key'] as String;
      if (rows.containsKey(key)) {
        throw ClinicApiException(
          'Duplicate record key in $table. Contact the clinic administrator.',
        );
      }
      _ownersByKey[key] = record['owner_id'] as String;
      ids[key] = record['id'] as String;
      versions[key] = record['version'] as int;
      rows[key] = Map<String, dynamic>.from(record['data']['value'] as Map);
    }
    restore(rows);
    baseline = _copy(read());
    dirty = false;
  }
}

final _recordKeys = Expando<String>('database key');
String databaseRecordKey(Object item, String suggested) =>
    _recordKeys[item] ??= '${ClinicApi.instance.accountId}:$suggested';
T databaseRestoreKey<T extends Object>(T item, String key) {
  _recordKeys[item] = key;
  return item;
}

final _ownersByKey = <String, String>{};
String? databaseOwnerOf(Object? item) =>
    item == null ? null : _ownersByKey[_recordKeys[item]];
T databaseAssignOwner<T extends Object>(
  T item,
  String suggested,
  String? ownerId,
) {
  final key = databaseRecordKey(item, suggested);
  if (ownerId != null) _ownersByKey[key] = ownerId;
  return item;
}
