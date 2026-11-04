import '../../core/deletable_chip.dart';
import '../../core/add_chip.dart';
import 'sale_editor.dart';
import '../../core/draft_guard.dart';
import '../farm/data/farm_crops.dart';

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/money.dart';
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
    if (n['items'] is List)
      for (final item
          in (n['items'] as List).whereType<Map<Object?, Object?>>().map(
            (e) => e.cast<String, dynamic>(),
          ))
        "${item['crop']} · ${item['quantity']} ${item['unit']}"
    else
      n['crop'],
    if (n['buyer'] != null) n['buyer'],
    if (n['incomePaise'] is int)
      formatRupees(n['incomePaise'] as int, showPaise: true),
    if (n['items'] is! List && n['quantity'] != null)
      '${n['quantity']} ${n['unit']}',
  ].where((v) => v != null && v.toString().isNotEmpty).join(' · ');
}

// Only known app labels are translated; descriptions, crop and buyer names stay literal.
String translatedLabel(BuildContext context, String value) {
  const labels = {
    'harvest': ['Harvest', 'ಕೊಯ್ಲು'],
    'ಕೊಯ್ಲು': ['Harvest', 'ಕೊಯ್ಲು'],
    'sale': ['Sold to Buyer', 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ'],
    'fertiliser': ['Fertiliser', 'ಗೊಬ್ಬರ'],
    'ಗೊಬ್ಬರ': ['Fertiliser', 'ಗೊಬ್ಬರ'],
    'spray': ['Spray', 'ಸಿಂಪಡಣೆ'],
    'ಸಿಂಪಡಣೆ': ['Spray', 'ಸಿಂಪಡಣೆ'],
    'irrigation': ['Irrigation', 'ನೀರಾವರಿ'],
    'ನೀರಾವರಿ': ['Irrigation', 'ನೀರಾವರಿ'],
  };
  final pair = labels[value.toLowerCase()];
  return pair == null ? value : v1Text(context, pair[0], pair[1]);
}

final workLabelsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAll([db.appSettings], () async {
    final value = await db.setting('custom_work_labels');
    return value == null
        ? <String>[]
        : (jsonDecode(value) as List).cast<String>();
  });
});

final hiddenWorkLabelsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAll([db.appSettings], () async {
    final value = await db.setting('hidden_work_labels');
    return value == null
        ? <String>{}
        : (jsonDecode(value) as List).cast<String>().toSet();
  });
});

String localizedNote(BuildContext context, String raw) {
  if (!raw.startsWith(notePrefix)) return raw;
  final n = noteValues(raw);
  return [
    n['description'],
    if (n['items'] is List)
      for (final item
          in (n['items'] as List).whereType<Map<Object?, Object?>>().map(
            (e) => e.cast<String, dynamic>(),
          ))
        "${item['crop']} · ${item['quantity']} ${item['unit'] == 'bags' ? v1Text(context, 'bags', 'ಚೀಲಗಳು') : v1Text(context, 'kg', 'ಕೆಜಿ')}"
    else
      n['crop'],
    n['buyer'],
    if (n['incomePaise'] is int) context.fmt.money(n['incomePaise'] as int),
    if (n['items'] is! List && n['quantity'] != null)
      "${n['quantity']} ${n['unit'] == 'bags' ? v1Text(context, 'bags', 'ಚೀಲಗಳು') : v1Text(context, 'kg', 'ಕೆಜಿ')}",
  ].where((v) => v != null && v.toString().isNotEmpty).join(' · ');
}

final myCropsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAll([
    db.appSettings,
    db.plots,
    db.plotCrops,
  ], () => loadFarmCrops(db));
});

class DateNoteEditor extends ConsumerStatefulWidget {
  const DateNoteEditor({
    super.key,
    required this.date,
    this.existing,
    this.suggested = '',
    this.initialValues = const {},
  });
  final DateTime date;
  final Reminder? existing;
  final String suggested;
  final Map<String, dynamic> initialValues;
  @override
  ConsumerState<DateNoteEditor> createState() => _DateNoteState();
}

class _DateNoteState extends ConsumerState<DateNoteEditor> {
  final form = GlobalKey<FormState>();
  late final label = TextEditingController(
    text: widget.existing?.title == 'sale'
        ? 'sale'
        : widget.existing != null &&
              noteValues(widget.existing!.notes)['labelSource'] != 'custom'
        ? translatedLabel(context, widget.existing!.title)
        : widget.existing?.title ?? widget.suggested,
  );
  late final values = widget.existing == null
      ? widget.initialValues
      : noteValues(widget.existing!.notes);
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
  late final buyer = TextEditingController(
    text: values['buyer']?.toString() ?? '',
  );
  late final income = TextEditingController(
    text: paiseToInput(values['incomePaise'] as int?),
  );
  bool get sale => label.text == 'sale';
  late bool customLabel = values['labelSource'] == 'custom';
  bool busy = false;
  bool get harvest =>
      ['harvest', 'ಕೊಯ್ಲು'].contains(label.text.trim().toLowerCase());
  @override
  void dispose() {
    for (final c in [label, description, crop, quantity, buyer, income]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> hideWorkType(String key) async {
    final remove =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              v1Text(c, 'Remove suggestion?', 'ಸೂಚನೆ ತೆಗೆದುಹಾಕಬೇಕೇ?'),
            ),
            content: Text(
              v1Text(
                c,
                'This removes only this work-type suggestion. Saved farm records stay unchanged. Add it again with Add work type.',
                'ಈ ಕೆಲಸದ ಸೂಚನೆ ಮಾತ್ರ ತೆಗೆದುಹಾಕುತ್ತದೆ. ಉಳಿಸಿದ ದಾಖಲೆಗಳು ಬದಲಾಗುವುದಿಲ್ಲ. ಹೊಸ ಕೆಲಸದ ಪ್ರಕಾರವಾಗಿ ಮತ್ತೆ ಸೇರಿಸಬಹುದು.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(c.l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(v1Text(c, 'Remove', 'ತೆಗೆದುಹಾಕಿ')),
              ),
            ],
          ),
        ) ??
        false;
    if (!remove || !mounted) return;
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      final saved = await db.setting('hidden_work_labels');
      final all = saved == null
          ? <String>{}
          : (jsonDecode(saved) as List).cast<String>().toSet();
      all.add(key);
      await db.putSetting('hidden_work_labels', jsonEncode(all.toList()));
    });
  }

  Future<void> addWorkType(String value) async {
    if (!mounted || value.isEmpty) return;
    setState(() {
      label.text = value;
      customLabel = true;
    });
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      final saved = await db.setting('custom_work_labels');
      final labels = saved == null
          ? <String>[]
          : (jsonDecode(saved) as List).cast<String>();
      if (!labels.contains(value)) {
        labels.add(value);
      }
      await db.putSetting('custom_work_labels', jsonEncode(labels));
      final hiddenValue = await db.setting('hidden_work_labels');
      final hidden = hiddenValue == null
          ? <String>{}
          : (jsonDecode(hiddenValue) as List).cast<String>().toSet();
      hidden.remove('custom:$value');
      await db.putSetting('hidden_work_labels', jsonEncode(hidden.toList()));
    });
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        if (!harvest && !sale && customLabel) {
          final saved = await db.setting('custom_work_labels');
          final labels = saved == null
              ? <String>[]
              : (jsonDecode(saved) as List).cast<String>();
          if (!labels.contains(label.text.trim())) {
            labels.add(label.text.trim());
          }
          await db.putSetting('custom_work_labels', jsonEncode(labels));
        }
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
                        if (values['harvestId'] != null)
                          'harvestId': values['harvestId'],
                        'labelSource': customLabel ? 'custom' : 'builtin',
                        if (sale) 'buyer': buyer.text.trim(),
                        if (sale) 'incomePaise': parseRupees(income.text),
                        'crop': crop.text.trim(),
                        if (harvest || sale)
                          'quantity': parseQty(quantity.text),
                        if (harvest || sale) 'unit': unit,
                      }),
                ),
                updatedAt: Value(DateTime.now()),
              ),
            );
        if (crop.text.trim().isNotEmpty) {
          final all = await loadFarmCrops(db);
          if (!all.contains(crop.text.trim())) {
            all.add(crop.text.trim());
            await db.putSetting('my_crops', jsonEncode(all));
          }
        }
      });
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
    if (sale) {
      return SaleEditor(
        date: widget.date,
        existing: widget.existing,
        initialValues: widget.initialValues,
      );
    }
    final l = context.l;
    final crops = ref.watch(myCropsProvider).value ?? [];
    final hidden = ref.watch(hiddenWorkLabelsProvider).value ?? <String>{};
    return Scaffold(
      appBar: AppBar(
        title: Text(
          sale
              ? v1Text(context, 'Sold to Buyer', 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ')
              : harvest
              ? l.navHarvest
              : l.farmActivity,
        ),
      ),
      body: DraftGuard(
        controllers: [label, description, crop, quantity, buyer, income],
        extra: () => [date.toIso8601String(), unit],
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                context.fmt.weekdayDate(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (sale)
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    v1Text(context, 'Change sale date', 'ಮಾರಾಟದ ದಿನಾಂಕ ಬದಲಿಸಿ'),
                  ),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                    );
                    if (mounted && selected != null) {
                      setState(() => date = selected);
                    }
                  },
                ),
              const SizedBox(height: 16),
              if (!harvest && !sale)
                FormField<String>(
                  validator: (_) =>
                      label.text.trim().isEmpty ? l.requiredField : null,
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v1Text(
                          context,
                          'Work type (required)',
                          'ಕೆಲಸದ ಪ್ರಕಾರ (ಅಗತ್ಯ)',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (label.text.isNotEmpty)
                        Text(
                          customLabel
                              ? label.text
                              : translatedLabel(context, label.text),
                        ),
                      if (state.hasError)
                        Text(
                          state.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              if (!harvest && !sale)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final pair in [
                      ('Fertiliser', 'ಗೊಬ್ಬರ'),
                      ('Spray', 'ಸಿಂಪಡಣೆ'),
                      ('Irrigation', 'ನೀರಾವರಿ'),
                    ])
                      if (!hidden.contains(pair.$1.toLowerCase()))
                        GestureDetector(
                          onLongPress: () => perform(
                            context,
                            () => hideWorkType(pair.$1.toLowerCase()),
                          ),
                          child: InputChip(
                            selected:
                                !customLabel &&
                                label.text == v1Text(context, pair.$1, pair.$2),
                            onDeleted: () => perform(
                              context,
                              () => hideWorkType(pair.$1.toLowerCase()),
                            ),
                            label: Text(v1Text(context, pair.$1, pair.$2)),
                            onPressed: () => setState(() {
                              label.text = v1Text(context, pair.$1, pair.$2);
                              customLabel = false;
                            }),
                          ),
                        ),
                  ],
                ),
              if (!harvest && !sale)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final custom
                        in ref.watch(workLabelsProvider).value ?? <String>[])
                      if (!hidden.contains('custom:$custom'))
                        GestureDetector(
                          onLongPress: () => perform(
                            context,
                            () => hideWorkType('custom:$custom'),
                          ),
                          child: InputChip(
                            selected: customLabel && label.text == custom,
                            onDeleted: () => perform(
                              context,
                              () => hideWorkType('custom:$custom'),
                            ),
                            label: Text(custom),
                            onPressed: () => setState(() {
                              label.text = custom;
                              customLabel = true;
                            }),
                          ),
                        ),
                  ],
                ),
              if (!harvest && !sale)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AddChip(
                    title: v1Text(
                      context,
                      'Add work type',
                      'ಕೆಲಸದ ಪ್ರಕಾರ ಸೇರಿಸಿ',
                    ),
                    onAdd: addWorkType,
                  ),
                ),
              TextFormField(
                controller: description,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: v1Text(
                    context,
                    'What was done?',
                    'ಏನು ಮಾಡಲಾಯಿತು?',
                  ),
                ),
                validator: (v) => !harvest && !sale && (v ?? '').trim().isEmpty
                    ? l.requiredField
                    : null,
              ),
              const SizedBox(height: 16),
              FormField<String>(
                validator: (_) => harvest && crop.text.trim().isEmpty
                    ? l.requiredField
                    : null,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      harvest
                          ? v1Text(context, 'Crop (required)', 'ಬೆಳೆ (ಅಗತ್ಯ)')
                          : v1Text(context, 'Crop (optional)', 'ಬೆಳೆ (ಐಚ್ಛಿಕ)'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final c in {
                          ...crops,
                          if (crop.text.isNotEmpty) crop.text,
                        })
                          DeletableChip(
                            label: c,
                            onRemove: () async {
                              await removeFarmCrop(
                                ref.read(databaseProvider),
                                c,
                              );
                              if (mounted && crop.text == c) {
                                setState(() => crop.clear());
                              }
                            },
                            selected: crop.text == c,
                            onPressed: () => setState(
                              () => crop.text = crop.text == c ? '' : c,
                            ),
                          ),
                        AddChip(
                          title: v1Text(context, 'Add crop', 'ಬೆಳೆ ಸೇರಿಸಿ'),
                          onAdd: (value) async {
                            final db = ref.read(databaseProvider);
                            await db.transaction(() async {
                              final all = await loadFarmCrops(db);
                              if (!all.contains(value)) {
                                all.add(value);
                              }
                              await saveFarmCrops(db, all);
                            });
                            if (mounted) {
                              setState(() => crop.text = value);
                            }
                          },
                        ),
                      ],
                    ),
                    if (state.hasError)
                      Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              if (harvest || sale) ...[
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
              if (sale) ...[
                TextFormField(
                  controller: buyer,
                  decoration: InputDecoration(
                    labelText: v1Text(
                      context,
                      'Sold to whom?',
                      'ಯಾರಿಗೆ ಮಾರಾಟ ಮಾಡಲಾಗಿದೆ?',
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: income,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: v1Text(
                      context,
                      'Income received (₹)',
                      'ಪಡೆದ ಆದಾಯ (₹)',
                    ),
                  ),
                  validator: (v) =>
                      (parseRupees(v ?? '') ?? 0) <= 0 ? l.invalidNumber : null,
                ),
              ],
              if (harvest && widget.existing != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    v1Text(context, 'Sold to Buyer', 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ'),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DateNoteEditor(
                        date: DateTime.now(),
                        suggested: 'sale',
                        initialValues: {
                          'crop': crop.text,
                          'quantity': parseQty(quantity.text),
                          'unit': unit,
                          'harvestId': widget.existing!.id,
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(onPressed: busy ? null : save, child: Text(l.save)),
            ],
          ),
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
                        acceptDrafts();
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
