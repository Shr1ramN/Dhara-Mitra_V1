import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../data/farm_repository.dart';

final switchFarmProvider = Provider<Future<void> Function(String)>(
  (ref) => (_) async {},
);
final returnToFarmProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);
final deleteFarmProvider = Provider<Future<void> Function(String)>(
  (ref) =>
      (_) async => throw StateError('Farm host unavailable'),
);
final profilesProvider = FutureProvider<List<(String, String)>>((ref) async {
  final catalogue = await ref.watch(farmCatalogueProvider);
  final state = await catalogue.read();
  final rows = <(String, String)>[];
  for (final id in state.ids) {
    final current = ref.watch(databaseProvider);
    final db = id == current.profileId
        ? current
        : AppDatabase.onDevice(profileId: id);
    try {
      rows.add((id, (await FarmRepository(db).getFarm())?.name ?? ''));
    } finally {
      if (db != current) await db.close();
    }
  }
  return rows;
});

class FarmsScreen extends ConsumerStatefulWidget {
  const FarmsScreen({super.key});
  @override
  ConsumerState<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends ConsumerState<FarmsScreen> {
  bool _busy = false;
  Future<void> _delete((String, String) farm) async {
    final l = context.l;
    if (!await confirm(
          context,
          title:
              '${l.fDeleteFarm}: ${farm.$2.isEmpty ? l.setupTitle : farm.$2}',
          body: l.fDeleteFarmBody,
        ) ||
        !mounted) {
      return;
    }
    final delete = ref.read(deleteFarmProvider);
    setState(() => _busy = true);
    try {
      await delete(farm.$1);
      if (mounted) ref.invalidate(profilesProvider);
    } catch (_) {
      if (mounted) showSnack(context, l.xInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switch({String? id}) async {
    setState(() => _busy = true);
    try {
      final target = id ?? await (await ref.read(farmCatalogueProvider)).add();
      await ref.read(switchFarmProvider)(target);
    } catch (_) {
      if (mounted) showSnack(context, context.l.xInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.fFarms)),
    body: AsyncBody(
      value: ref.watch(profilesProvider),
      builder: (farms) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l.fFarmSeparate),
          const SizedBox(height: 16),
          for (final farm in farms)
            PaddedCard(
              child: ListTile(
                leading: const Icon(Icons.agriculture_outlined),
                title: Text(farm.$2.isEmpty ? context.l.setupTitle : farm.$2),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (farm.$1 == ref.watch(databaseProvider).profileId)
                      const Icon(Icons.check_circle),
                    IconButton(
                      key: ValueKey('delete-farm-${farm.$1}'),
                      tooltip: context.l.fDeleteFarm,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _delete(farm),
                    ),
                  ],
                ),
                onTap: _busy ? null : () => _switch(id: farm.$1),
              ),
            ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _switch(),
            icon: const Icon(Icons.add),
            label: Text(context.l.fAddFarm),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    ),
  );
}
