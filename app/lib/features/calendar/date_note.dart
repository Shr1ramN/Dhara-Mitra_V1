import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/v1.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../labour/ui/saved_tick.dart';

const notePrefix = '@dm-note:';
Map<String, dynamic> noteValues(String text) {
  if (text.startsWith(notePrefix)) {
    try {
      return (jsonDecode(text.substring(notePrefix.length)) as Map)
          .cast<String, dynamic>();
    } catch (_) {
      /* Preserve older notes as plain text. */
    }
  }
  return {'description': text};
}

String readableNote(String text) {
  final n = noteValues(text);
  return [
    n['description'],
    n['crop'],
    if (n['quantity'] != null) '${n['quantity']} ${n['unit']}',
  ].where((v) => v != null && v.toString().isNotEmpty).join(' · ');
}

final myCropsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAll([db.appSettings], () async {
    final raw = await db.setting('my_crops');
    return raw == null ? <String>[] : (jsonDecode(raw) as List).cast<String>();
  });
});

class DateNoteEditor extends ConsumerStatefulWidget {
  const DateNoteEditor({
    super.key,
    required this.date,
    this.existing,
    this.suggested = '',
  });
  final DateTime date;
  final Reminder? existing;
  final String suggested;
  @override
  ConsumerState<DateNoteEditor> createState() => _DateNoteState();
}

class _DateNoteState extends ConsumerState<DateNoteEditor> {
  final form = GlobalKey<FormState>();
  late final label = TextEditingController(
    text: widget.existing?.title ?? widget.suggested,
  );
  late final values = noteValues(widget.existing?.notes ?? '');
  late final description = TextEditingController(
    text: values['description']?.toString() ?? '',
  );
  late final crop = TextEditingController(
    text: values['crop']?.toString() ?? '',
  );
  late final quantity = TextEditingController(
    text: values['quantity']?.toString() ?? '',
  );
  late String unit = values['unit']?.toString() ?? 'kg';
  late DateTime date = widget.existing?.dueOn ?? widget.date;
  bool busy = false;
  bool get harvest =>
      ['harvest', 'ಕೊಯ್ಲು'].contains(label.text.trim().toLowerCase());
  @override
  void dispose() {
    for (final c in [label, description, crop, quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        await db
            .into(db.reminders)
            .insertOnConflictUpdate(
              RemindersCompanion.insert(
                id: widget.existing == null
                    ? const Value.absent()
                    : Value(widget.existing!.id),
                title: label.text.trim(),
                dueOn: date,
                kind: const Value('dateNote'),
                done: const Value(true),
                notes: Value(
                  notePrefix +
                      jsonEncode({
                        'description': description.text.trim(),
                        'crop': crop.text.trim(),
                        if (harvest) 'quantity': parseQty(quantity.text),
                        if (harvest) 'unit': unit,
                      }),
                ),
                updatedAt: Value(DateTime.now()),
              ),
            );
        if (crop.text.trim().isNotEmpty) {
          final all = [...?ref.read(myCropsProvider).value];
          if (!all.contains(crop.text.trim())) {
            all.add(crop.text.trim());
            await db.putSetting('my_crops', jsonEncode(all));
          }
        }
      });
      if (mounted) {
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
    final crops = ref.watch(myCropsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(context.l.farmDateNote)),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.fmt.weekdayDate(date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: label,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: v1Text(context, 'Label', 'ವರ್ಗ'),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final pair in [
                  ('Fertiliser', 'ಗೊಬ್ಬರ'),
                  ('Spray', 'ಸಿಂಪಡಣೆ'),
                  ('Harvest', 'ಕೊಯ್ಲು'),
                  ('Irrigation', 'ನೀರಾವರಿ'),
                ])
                  ActionChip(
                    label: Text(v1Text(context, pair.$1, pair.$2)),
                    onPressed: () => setState(
                      () => label.text = v1Text(context, pair.$1, pair.$2),
                    ),
                  ),
              ],
            ),
            TextFormField(
              controller: description,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: v1Text(context, 'What was done?', 'ಏನು ಮಾಡಲಾಯಿತು?'),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: crop,
              decoration: InputDecoration(
                labelText: v1Text(context, 'Crop (optional)', 'ಬೆಳೆ (ಐಚ್ಛಿಕ)'),
              ),
            ),
            if (crops.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final c in crops)
                    ActionChip(label: Text(c), onPressed: () => crop.text = c),
                ],
              ),
            if (harvest) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l.xQuantity),
                validator: (v) =>
                    (parseQty(v ?? '') ?? 0) <= 0 ? l.invalidNumber : null,
              ),
              RadioGroup<String>(
                groupValue: unit,
                onChanged: (v) => setState(() => unit = v!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: 'bags',
                      title: Text(v1Text(context, 'Bags', 'ಚೀಲಗಳು')),
                    ),
                    RadioListTile(value: 'kg', title: Text(l.kgUnit)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: busy ? null : save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}

class MyCropsScreen extends ConsumerStatefulWidget {
  const MyCropsScreen({super.key});
  @override
  ConsumerState<MyCropsScreen> createState() => _CropsState();
}

class _CropsState extends ConsumerState<MyCropsScreen> {
  final name = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.myCrops)),
    body: AsyncBody(
      value: ref.watch(myCropsProvider),
      builder: (crops) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: v1Text(
                context,
                'What do you grow?',
                'ನೀವು ಯಾವ ಬೆಳೆ ಬೆಳೆಯುತ್ತೀರಿ?',
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.l.save),
            onPressed: busy
                ? null
                : () async {
                    final text = name.text.trim();
                    if (text.isEmpty) return;
                    setState(() => busy = true);
                    try {
                      await ref
                          .read(databaseProvider)
                          .putSetting(
                            'my_crops',
                            jsonEncode({...crops, text}.toList()),
                          );
                      name.clear();
                      if (context.mounted) {
                        showSavedTick(context, context.l.saved);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showSnack(context, failureText(context, e));
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
          ),
          for (final c in crops)
            ListTile(leading: const Icon(Icons.grass), title: Text(c)),
        ],
      ),
    ),
  );
}
