import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../common/forms.dart';
import '../../common/labels.dart';
import '../../documents/documents_screen.dart';

class CropDetailsScreen extends ConsumerWidget {
  const CropDetailsScreen(this.plotId, {super.key});
  final String plotId;
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PlotCrop? crop,
  ]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xCropDetails,
      fields: [
        EntryField(
          'crop',
          l.xCrop,
          kind: InputKind.choice,
          required: true,
          initial: crop?.crop ?? 'areca',
          options: cropOptions(context),
        ),
        EntryField(
          'count',
          l.xCount,
          kind: InputKind.integer,
          required: true,
          positive: true,
          initial: crop?.count,
        ),
        EntryField('variety', l.xVariety, initial: crop?.variety),
        EntryField(
          'planted',
          l.xPlantedOn,
          kind: InputKind.date,
          initial: crop?.plantedOn,
        ),
        EntryField(
          'bearing',
          l.xBearing,
          kind: InputKind.toggle,
          initial: crop?.bearing ?? true,
        ),
        EntryField(
          'ratoon',
          l.xRatoon,
          kind: InputKind.integer,
          initial: crop?.ratoon ?? 0,
        ),
        EntryField('trailed', l.xTrailedOn, initial: crop?.trailedOn),
      ],
      onSave: (v) => ref.read(databaseProvider).transaction(() async {
        final db = ref.read(databaseProvider);
        await db
            .into(db.plotCrops)
            .insertOnConflictUpdate(
              PlotCropsCompanion.insert(
                id: crop == null ? const Value.absent() : Value(crop.id),
                plotId: plotId,
                crop: v.text('crop'),
                count: Value(v.integer('count')),
                variety: Value(v.text('variety')),
                plantedOn: Value(v.optionalDate('planted')),
                bearing: Value(v.flag('bearing')),
                ratoon: Value(v.integer('ratoon')),
                trailedOn: Value(v.text('trailed')),
                updatedAt: Value(DateTime.now()),
              ),
            );
        final profiles = await (db.select(
          db.plotCrops,
        )..where((p) => p.plotId.equals(plotId))).get();
        for (final kind in {v.text('crop'), if (crop != null) crop.crop}) {
          final count = profiles
              .where((p) => p.crop == kind && !p.deleted)
              .fold(0, (s, p) => s + p.count);
          final value = Value(count);
          final changes = switch (Crop.values.byName(kind)) {
            Crop.areca => PlotsCompanion(arecaPalms: value),
            Crop.coconut => PlotsCompanion(coconutTrees: value),
            Crop.pepper => PlotsCompanion(pepperVines: value),
            Crop.banana => PlotsCompanion(bananaClumps: value),
          };
          await (db.update(db.plots)..where((p) => p.id.equals(plotId))).write(
            changes.copyWith(updatedAt: Value(DateTime.now())),
          );
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.xCropDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: l.xDocuments,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentsScreen(refType: 'plot', refId: plotId),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.add),
      ),
      body: StreamBuilder<List<PlotCrop>>(
        stream:
            (db.select(db.plotCrops)
                  ..where((p) => p.plotId.equals(plotId))
                  ..orderBy([(p) => OrderingTerm.asc(p.crop)]))
                .watch(),
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            for (final p in (snapshot.data ?? const <PlotCrop>[]).where(
              (p) => !p.deleted,
            ))
              Card(
                child: ListTile(
                  title: Text('${recordLabel(context, p.crop)} · ${p.count}'),
                  subtitle: Text(
                    '${p.variety} · ${p.bearing ? l.xBearing : l.xPending}${p.plantedOn == null ? '' : '\n${l.xPlantedOn}: ${context.fmt.date(p.plantedOn!)}'}',
                  ),
                  onTap: () => _edit(context, ref, p),
                  trailing: IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip: l.xDocuments,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DocumentsScreen(refType: 'crop', refId: p.id),
                      ),
                    ),
                  ),
                ),
              ),
            if ((snapshot.data ?? const <PlotCrop>[]).isEmpty)
              EmptyState(icon: Icons.park_outlined, text: l.xEmpty),
          ],
        ),
      ),
    );
  }
}
