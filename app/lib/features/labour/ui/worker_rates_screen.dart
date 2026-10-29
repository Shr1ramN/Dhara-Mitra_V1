import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../common/forms.dart';

final workerRatesProvider = StreamProvider.family<List<WorkerRate>, String>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.workerRates,
  )..where((r) => r.workerId.equals(id))).watch();
});

class WorkerRatesScreen extends ConsumerWidget {
  const WorkerRatesScreen(this.workerId, {super.key});
  final String workerId;
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    WorkerRate? rate,
  ]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xRate,
      fields: [
        EntryField('work', l.xType, required: true, initial: rate?.work),
        EntryField(
          'unit',
          l.xUnit,
          kind: InputKind.choice,
          required: true,
          initial: rate?.unit ?? 'day',
          options: {
            for (final unit in RateUnit.values) unit.name: l.unit(unit),
          },
        ),
        EntryField(
          'rate',
          l.xRate,
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: rate == null ? null : paiseToInput(rate.rate),
        ),
      ],
      onSave: (v) async {
        final db = ref.read(databaseProvider);
        await db
            .into(db.workerRates)
            .insertOnConflictUpdate(
              WorkerRatesCompanion.insert(
                id: rate == null ? const Value.absent() : Value(rate.id),
                workerId: workerId,
                work: v.text('work'),
                unit: v.text('unit'),
                rate: v.money('rate'),
                updatedAt: Value(DateTime.now()),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.xRate)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(context, ref),
      icon: const Icon(Icons.add),
      label: Text(context.l.add),
    ),
    body: ref
        .watch(workerRatesProvider(workerId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(context.l.xError)),
          data: (rates) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              for (final rate in rates.where((r) => !r.deleted))
                ListTile(
                  title: Text(rate.work),
                  subtitle: Text(
                    context.fmt.rate(
                      rate.rate,
                      RateUnit.values.byName(rate.unit),
                    ),
                  ),
                  onTap: () => _edit(context, ref, rate),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.l.delete,
                    onPressed: () => perform(context, () async {
                      final db = ref.read(databaseProvider);
                      await (db.update(
                        db.workerRates,
                      )..where((r) => r.id.equals(rate.id))).write(
                        WorkerRatesCompanion(
                          deleted: const Value(true),
                          updatedAt: Value(DateTime.now()),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
  );
}
