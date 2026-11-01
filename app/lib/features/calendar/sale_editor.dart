import '../../core/deletable_chip.dart';

import 'package:go_router/go_router.dart';

import '../../core/add_chip.dart';

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/draft_guard.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/v1.dart';
import '../../core/widgets.dart';
import '../farm/data/farm_crops.dart';
import '../common/forms.dart';
import '../labour/ui/saved_tick.dart';
import 'date_note.dart';

class SaleEditor extends ConsumerStatefulWidget {
  const SaleEditor({
    super.key,
    required this.date,
    this.existing,
    this.initialValues = const {},
  });
  final DateTime date;
  final Reminder? existing;
  final Map<String, dynamic> initialValues;
  @override
  ConsumerState<SaleEditor> createState() => _SaleState();
}

class _SaleItem {
  _SaleItem(this.crop, {String quantity = '', this.unit = 'kg'})
    : quantity = TextEditingController(text: quantity);
  final String crop;
  final TextEditingController quantity;
  String unit;
}

class _SaleState extends ConsumerState<SaleEditor> {
  final form = GlobalKey<FormState>();
  late final values = widget.existing == null
      ? widget.initialValues
      : noteValues(widget.existing!.notes);
  late DateTime date = widget.existing?.dueOn ?? widget.date;
  late final buyer = TextEditingController(
    text: values['buyer']?.toString() ?? '',
  );
  late final income = TextEditingController(
    text: paiseToInput(values['incomePaise'] as int?),
  );
  late final notes = TextEditingController(
    text: values['description']?.toString() ?? '',
  );
  final newCrop = TextEditingController();
  late final List<_SaleItem> items = [
    if (values['items'] is List)
      for (final item
          in (values['items'] as List).whereType<Map<Object?, Object?>>().map(
            (e) => e.cast<String, dynamic>(),
          ))
        _SaleItem(
          item['crop'] as String,
          quantity: item['quantity']?.toString() ?? '',
          unit: item['unit'] as String? ?? 'kg',
        )
    else if ((values['crop']?.toString() ?? '').isNotEmpty)
      _SaleItem(
        values['crop'].toString(),
        quantity: values['quantity']?.toString() ?? '',
        unit: values['unit'] as String? ?? 'kg',
      ),
  ];
  final retired = <_SaleItem>[];
  bool busy = false;
  @override
  void dispose() {
    for (final c in [
      buyer,
      income,
      notes,
      newCrop,
      ...items.map((i) => i.quantity),
      ...retired.map((i) => i.quantity),
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> addCrop() async {
    final name = newCrop.text.trim();
    if (name.isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      final all = await loadFarmCrops(db);
      if (!all.any((c) => c.toLowerCase() == name.toLowerCase())) {
        all.add(name);
        await saveFarmCrops(db, all);
      }
    });
    if (!mounted) return;
    setState(() {
      if (!items.any((i) => i.crop.toLowerCase() == name.toLowerCase())) {
        items.add(_SaleItem(name));
      }
      newCrop.clear();
    });
  }

  Future<void> save() async {
    if (busy) return;
    if (items.isEmpty) {
      showSnack(
        context,
        v1Text(
          context,
          'Select at least one crop.',
          'ಕನಿಷ್ಠ ಒಂದು ಬೆಳೆ ಆಯ್ಕೆಮಾಡಿ.',
        ),
      );
      return;
    }
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final rows = [
        for (final i in items)
          {
            'crop': i.crop,
            'quantity': parseQty(i.quantity.text),
            'unit': i.unit,
          },
      ];
      await ref.read(databaseProvider).transaction(() async {
        await ref
            .read(databaseProvider)
            .into(ref.read(databaseProvider).reminders)
            .insertOnConflictUpdate(
              RemindersCompanion.insert(
                id: widget.existing == null
                    ? const Value.absent()
                    : Value(widget.existing!.id),
                title: 'sale',
                dueOn: date,
                kind: const Value('dateNote'),
                done: const Value(true),
                updatedAt: Value(DateTime.now()),
                notes: Value(
                  notePrefix +
                      jsonEncode({
                        'labelSource': 'builtin',
                        'description': notes.text.trim(),
                        'buyer': buyer.text.trim(),
                        'incomePaise': parseRupees(income.text),
                        'crop': items.map((i) => i.crop).join(', '),
                        'items': rows,
                        if (items.length == 1)
                          'quantity': rows.first['quantity'],
                        if (items.length == 1) 'unit': rows.first['unit'],
                        if (values['harvestId'] != null)
                          'harvestId': values['harvestId'],
                      }),
                ),
              ),
            );
        final crops = await loadFarmCrops(ref.read(databaseProvider));
        for (final i in items) {
          if (!crops.contains(i.crop)) crops.add(i.crop);
        }
        await saveFarmCrops(ref.read(databaseProvider), crops);
      });
      if (mounted) {
        acceptDrafts();
        showSavedTick(context, context.l.saved);
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          context.go('/');
        }
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
    final crops = {
      ...?ref.watch(myCropsProvider).value,
      ...items.map((i) => i.crop),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(v1Text(context, 'Sold to Buyer', 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ')),
      ),
      body: DraftGuard(
        controllers: [
          buyer,
          income,
          notes,
          newCrop,
          ...items.map((i) => i.quantity),
        ],
        extra: () => [
          date.toIso8601String(),
          for (final i in items) [i.crop, i.unit],
        ],
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                context.fmt.weekdayDate(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  v1Text(context, 'Change sale date', 'ಮಾರಾಟದ ದಿನಾಂಕ ಬದಲಿಸಿ'),
                ),
                onPressed: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                  );
                  if (value != null && mounted) setState(() => date = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                v1Text(
                  context,
                  'Crops sold (required)',
                  'ಮಾರಾಟ ಮಾಡಿದ ಬೆಳೆಗಳು (ಅಗತ್ಯ)',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                v1Text(
                  context,
                  'Select one or more farm crops, or add a crop below.',
                  'ಒಂದು ಅಥವಾ ಹೆಚ್ಚಿನ ಬೆಳೆಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ ಅಥವಾ ಕೆಳಗೆ ಹೊಸ ಬೆಳೆ ಸೇರಿಸಿ.',
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in crops)
                    DeletableChip(
                      label: c,
                      onRemove: () async {
                        await removeFarmCrop(ref.read(databaseProvider), c);
                        if (mounted) {
                          setState(() {
                            final removed = items
                                .where((i) => i.crop == c)
                                .toList();
                            items.removeWhere((i) => i.crop == c);
                            retired.addAll(removed);
                          });
                        }
                      },
                      selected: items.any((i) => i.crop == c),
                      onPressed: () => setState(() {
                        if (!items.any((i) => i.crop == c)) {
                          items.add(_SaleItem(c));
                        } else {
                          final i = items.firstWhere((i) => i.crop == c);
                          items.remove(i);
                          retired.add(i);
                        }
                      }),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AddChip(
                  title: v1Text(context, 'Add crop', 'ಬೆಳೆ ಸೇರಿಸಿ'),
                  onAdd: (value) async {
                    newCrop.text = value;
                    await addCrop();
                  },
                ),
              ),
              for (final i in items)
                Card(
                  key: ValueKey(i),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          i.crop,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: i.quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(labelText: l.xQuantity),
                          validator: (v) => (parseQty(v ?? '') ?? 0) <= 0
                              ? l.invalidNumber
                              : null,
                        ),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'kg', label: Text(l.kgUnit)),
                            ButtonSegment(
                              value: 'bags',
                              label: Text(v1Text(context, 'Bags', 'ಚೀಲಗಳು')),
                            ),
                          ],
                          selected: {i.unit},
                          onSelectionChanged: (v) =>
                              setState(() => i.unit = v.first),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
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
                    'Total income received (₹)',
                    'ಪಡೆದ ಒಟ್ಟು ಆದಾಯ (₹)',
                  ),
                ),
                validator: (v) =>
                    (parseRupees(v ?? '') ?? 0) <= 0 ? l.invalidNumber : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notes,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: v1Text(
                    context,
                    'Additional Notes (optional)',
                    'ಹೆಚ್ಚುವರಿ ಟಿಪ್ಪಣಿ (ಐಚ್ಛಿಕ)',
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
