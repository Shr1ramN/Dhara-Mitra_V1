import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db/database.dart';

/// Profile catalogue lives outside farm databases so restoring one farm cannot
/// remove the others. Existing installations retain their original database.
class FarmProfiles {
  FarmProfiles(this.root, {this.ownerId}) {
    if (ownerId != null && (!validId(ownerId!) || ownerId == 'default')) {
      throw ArgumentError('Invalid account');
    }
  }
  final Directory root;
  final String? ownerId;
  static Future<FarmProfiles> onDevice() async =>
      FarmProfiles(await getApplicationDocumentsDirectory());
  File get _file => File(
    p.join(
      root.path,
      ownerId == null ? 'farm-profiles.json' : 'farm-profiles-$ownerId.json',
    ),
  );

  /// Accounts use UUID farm IDs; only legacy local mode owns `default`.
  Future<void> initialize() async {
    if (ownerId == null || await _file.exists()) return;
    final id = newId();
    await _write(id, [id]);
  }

  static bool validId(String id) =>
      id == 'default' || RegExp(r'^[a-f0-9-]{36}$').hasMatch(id);

  Future<({String active, List<String> ids})> read() async {
    if (!await _file.exists()) {
      await initialize();
      if (ownerId == null) return (active: 'default', ids: ['default']);
    }
    final json = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    final ids = (json['ids'] as List<dynamic>).cast<String>();
    final active = json['active'] as String;
    if (ids.isEmpty ||
        ids.toSet().length != ids.length ||
        !ids.every(validId) ||
        !ids.contains(active)) {
      throw const FormatException('Invalid farm catalogue');
    }
    return (active: active, ids: ids);
  }

  Future<void> select(String id) async {
    final state = await read();
    if (!state.ids.contains(id)) throw ArgumentError('Unknown farm');
    await _write(id, state.ids);
  }

  Future<String> add() async {
    final state = await read();
    final id = newId();
    await _write(state.active, [...state.ids, id]);
    return id;
  }

  Future<void> remove(String id) async {
    final state = await read();
    if (!state.ids.contains(id)) throw ArgumentError('Unknown farm');
    if (state.active == id) throw StateError('Switch farms before deleting');
    await _write(state.active, state.ids.where((item) => item != id).toList());
  }

  /// Publish imported farms only after every database and attachment is ready.
  Future<void> register(List<String> ids) async {
    final state = await read();
    final combined = [...state.ids, ...ids];
    if (!ids.every(validId) || combined.toSet().length != combined.length) {
      throw ArgumentError('Invalid imported farms');
    }
    await _write(state.active, combined);
  }

  Future<void> _write(String active, List<String> ids) async {
    await root.create(recursive: true);
    final staged = File('${_file.path}.tmp');
    await staged.writeAsString(
      jsonEncode({'active': active, 'ids': ids}),
      flush: true,
    );
    await staged.rename(_file.path);
  }
}
