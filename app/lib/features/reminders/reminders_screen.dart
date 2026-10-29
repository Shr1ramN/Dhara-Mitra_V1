import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../common/feature_providers.dart';
import '../common/forms.dart';
import '../common/labels.dart';
import 'crop_calendar.dart';

Future<void> editReminder(
  BuildContext context,
  WidgetRef ref, {
  Reminder? existing,
  int? month,
  String? crop,
  String? suggestedTitle,
}) async {
  final l = context.l;
  final today = ref.read(todayProvider);
  await openEntryForm(
    context,
    title: l.xReminders,
    fields: [
      EntryField('title', l.xTitle, required: true, initial: existing?.title ?? suggestedTitle),
      EntryField(
        'date',
        l.xDueOn,
        kind: InputKind.date,
        required: true,
        initial:
            existing?.dueOn ??
            (month == null
                ? today
                : DateTime(
                    today.year + (month < today.month ? 1 : 0),
                    month,
                    1,
                  )),
      ),
      EntryField(
        'amount',
        l.xAmount,
        kind: InputKind.money,
        initial: existing?.amount == null ? null : existing!.amount! / 100,
      ),
      EntryField(
        'notes',
        l.notes,
        kind: InputKind.notes,
        initial: existing?.notes,
      ),
    ],
    onSave: (v) async {
      final db = ref.read(databaseProvider);
      await db
          .into(db.reminders)
          .insertOnConflictUpdate(
            RemindersCompanion.insert(
              id: existing == null ? const Value.absent() : Value(existing.id),
              title: v.text('title'),
              dueOn: v.date('date'),
              kind: Value(
                existing?.kind ?? (crop == null ? 'task' : 'calendar.$crop'),
              ),
              refId: Value(existing?.refId),
              amount: Value(v.money('amount') == 0 ? null : v.money('amount')),
              done: Value(existing?.done ?? false),
              notes: Value(v.text('notes')),
              updatedAt: Value(DateTime.now()),
            ),
          );
    },
  );
}

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _showDone = false;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.xReminders),
        actions: [
          IconButton(
            icon: Icon(
              _showDone ? Icons.check_box : Icons.check_box_outline_blank,
            ),
            tooltip: l.xDone,
            onPressed: () => setState(() => _showDone = !_showDone),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editReminder(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.xAddReminder),
      ),
      body: AsyncBody(
        value: ref.watch(remindersProvider),
        builder: (all) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l.xEnableNotifications),
              onPressed: () => perform(context, () async {
                final service = FarmNotifications(ref.read(databaseProvider));
                final enabled = await service.requestPermission();
                if (enabled) await service.syncReminders();
                if (context.mounted) {
                  showSnack(
                    context,
                    enabled ? l.saved : l.xAuthenticationFailed,
                  );
                }
              }),
            ),
            for (final r in all.where((r) => _showDone || !r.done))
              Card(
                child: ListTile(
                  leading: Checkbox(
                    value: r.done,
                    onChanged: (done) => perform(context, () async {
                      final db = ref.read(databaseProvider);
                      await (db.update(
                        db.reminders,
                      )..where((t) => t.id.equals(r.id))).write(
                        RemindersCompanion(
                          done: Value(done ?? false),
                          updatedAt: Value(DateTime.now()),
                        ),
                      );
                    }),
                  ),
                  title: Text(r.title),
                  subtitle: Text(
                    '${context.fmt.date(r.dueOn)}${!r.done && r.dueOn.isBefore(ref.read(todayProvider)) ? ' · ${l.xOverdue}' : ''}\n${r.notes}',
                  ),
                  onTap: () => editReminder(context, ref, existing: r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l.delete,
                    onPressed: () async {
                      if (await confirm(context, title: l.confirmDelete) &&
                          context.mounted) {
                        await perform(context, () async {
                          final db = ref.read(databaseProvider);
                          await (db.update(
                            db.reminders,
                          )..where((t) => t.id.equals(r.id))).write(
                            RemindersCompanion(
                              deleted: const Value(true),
                              updatedAt: Value(DateTime.now()),
                            ),
                          );
                        });
                      }
                    },
                  ),
                ),
              ),
            if (all.where((r) => _showDone || !r.done).isEmpty)
              EmptyState(icon: Icons.event_available_outlined, text: l.xEmpty),
          ],
        ),
      ),
    );
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late int _month = ref.read(todayProvider).month;
  String _crop = 'areca';
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.xCalendar)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editReminder(context, ref, month: _month, crop: _crop),
        icon: const Icon(Icons.add),
        label: Text(l.xAddReminder),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _month,
            decoration: InputDecoration(labelText: l.date),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(context.fmt.month(m))),
            ],
            onChanged: (v) => setState(() => _month = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _crop,
            decoration: InputDecoration(labelText: l.xCrop),
            items: [
              for (final e in cropOptions(context).entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _crop = v!),
          ),
          const SizedBox(height: 16),
          PaddedCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(cropCalendar[_month-1][_crop]![Localizations.localeOf(context).languageCode == 'kn' ? 1 : 0]),
            TextButton.icon(icon:const Icon(Icons.add_alert_outlined),label:Text(l.xAddReminder),
              onPressed:()=>editReminder(context,ref,month:_month,crop:_crop,
                suggestedTitle:cropCalendar[_month-1][_crop]![Localizations.localeOf(context).languageCode == 'kn' ? 1 : 0])),
          ])),
          AsyncBody(
            value: ref.watch(remindersProvider),
            builder: (all) {
              final tasks = all
                  .where(
                    (r) =>
                        r.kind == 'calendar.$_crop' && r.dueOn.month == _month,
                  )
                  .toList();
              return Column(
                children: [
                  if (tasks.isEmpty)
                    EmptyState(icon: Icons.calendar_month, text: l.xEmpty),
                  for (final r in tasks)
                    ListTile(
                      title: Text(r.title),
                      subtitle: Text(
                        '${context.fmt.date(r.dueOn)} · ${r.notes}',
                      ),
                      onTap: () => editReminder(context, ref, existing: r),
                      trailing: r.done
                          ? const Icon(Icons.check_circle_outline)
                          : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
