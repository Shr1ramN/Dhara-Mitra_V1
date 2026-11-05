import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/dates.dart';
import '../../core/draft_guard.dart';
import '../../core/form_fields.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../labour/ui/saved_tick.dart';
import 'date_note.dart';

class PurchaseEditor extends ConsumerStatefulWidget {
  const PurchaseEditor({super.key, required this.date, this.existing});
  final DateTime date;
  final Reminder? existing;

  @override
  ConsumerState<PurchaseEditor> createState() => _PurchaseState();
}

class _PurchaseState extends ConsumerState<PurchaseEditor> {
  final form = GlobalKey<FormState>();
  late final values = noteValues(widget.existing?.notes ?? '');
  late final item = TextEditingController(
    text: values['item']?.toString() ?? '',
  );
  late final cost = TextEditingController(
    text: paiseToInput(values['costPaise'] as int?),
  );
  late final notes = TextEditingController(
    text: values['description']?.toString() ?? '',
  );
  late DateTime date = dateOnly(widget.existing?.dueOn ?? widget.date);
  bool busy = false;

  @override
  void dispose() {
    for (final c in [item, cost, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final db = ref.read(databaseProvider);
      await db
          .into(db.reminders)
          .insertOnConflictUpdate(
            RemindersCompanion.insert(
              id: widget.existing == null
                  ? const Value.absent()
                  : Value(widget.existing!.id),
              title: 'purchase',
              dueOn: date,
              kind: const Value('dateNote'),
              done: const Value(true),
              notes: Value(
                notePrefix +
                    jsonEncode({
                      'labelSource': 'builtin',
                      'item': item.text.trim(),
                      'costPaise': parseRupees(cost.text)!,
                      'description': notes.text.trim(),
                    }),
              ),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (mounted) {
        acceptDrafts();
        showSavedTick(context, context.l.saved);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.farmPurchases),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: l.deleteEntry,
              icon: const Icon(Icons.delete_outline),
              onPressed: busy
                  ? null
                  : () async {
                      if (!await confirm(context, title: l.deleteEntry) ||
                          !context.mounted) {
                        return;
                      }
                      setState(() => busy = true);
                      await perform(context, () async {
                        final db = ref.read(databaseProvider);
                        await (db.update(db.reminders)
                              ..where((r) => r.id.equals(widget.existing!.id)))
                            .write(
                              RemindersCompanion(
                                deleted: const Value(true),
                                updatedAt: Value(DateTime.now()),
                              ),
                            );
                        if (context.mounted) {
                          acceptDrafts();
                          Navigator.pop(context);
                        }
                      });
                      if (mounted) setState(() => busy = false);
                    },
            ),
        ],
      ),
      body: DraftGuard(
        controllers: [item, cost, notes],
        extra: () => [date.toIso8601String()],
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DateField(
                label: l.date,
                value: date,
                onChanged: (d) => setState(() => date = dateOnly(d)),
              ),
              fieldGap,
              TextFormField(
                controller: item,
                decoration: InputDecoration(
                  labelText: l.purchasedItem,
                  hintText: l.purchasedItemHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.requiredField : null,
              ),
              fieldGap,
              MoneyField(
                controller: cost,
                label: l.purchaseCost,
                required: true,
                validator: (v) =>
                    (parseRupees(v) ?? 0) <= 0 ? l.invalidNumber : null,
              ),
              fieldGap,
              TextFormField(
                controller: notes,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.notes),
              ),
              fieldGap,
              Text(l.purchaseExpenseHint),
              fieldGap,
              FilledButton(onPressed: busy ? null : save, child: Text(l.save)),
            ],
          ),
        ),
      ),
    );
  }
}
