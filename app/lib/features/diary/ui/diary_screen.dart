import '../../../core/v1.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/widgets.dart';
import '../../common/feature_providers.dart';
import '../../common/forms.dart';
import '../../common/voice_notes_field.dart';
import '../../documents/documents_screen.dart';
import '../../lots/data/lots_repository.dart';
import '../../lots/ui/lot_sheets.dart';
import '../data/diary_repository.dart';

String activityLabel(BuildContext context, String kind) => switch (kind) {
  'manure' => v1Text(context, 'Manure', 'ಸಾವಯವ ಗೊಬ್ಬರ'),
  'fertiliser' => context.l.xFertiliser,
  'spray' => context.l.xSpray,
  'irrigation' => context.l.xIrrigation,
  'weeding' => context.l.xWeeding,
  'mulching' => context.l.xMulching,
  'harvest' => context.l.navHarvest,
  'cropCare' => context.l.xCropCare,
  _ => context.l.xOther,
};

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});
  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  String _search = '';
  String? _crop;
  String? _kind;
  String? _plot;
  DateTimeRange? _range;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final plots = ref.watch(plotsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.xDiary),
        actions: [
          IconButton(
            tooltip: l.date,
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2015),
                lastDate: DateTime(2100),
                initialDateRange: _range,
              );
              if (mounted && range != null) setState(() => _range = range);
            },
          ),
          if (_range != null)
            IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _range = null),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.xActivity),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiaryForm()),
        ),
      ),
      body: AsyncBody(
        value: ref.watch(diaryProvider),
        builder: (all) {
          final entries = all
              .where(
                (v) =>
                    (_search.isEmpty ||
                        '${v.activity.title} ${v.activity.notes}'
                            .toLowerCase()
                            .contains(_search)) &&
                    (_crop == null || v.activity.crops.contains(_crop)) &&
                    (_kind == null || v.activity.kind == _kind) &&
                    (_plot == null || v.activity.plotIds.contains(_plot)) &&
                    (_range == null ||
                        (!v.activity.date.isBefore(_range!.start) &&
                            v.activity.date.isBefore(
                              _range!.end.add(const Duration(days: 1)),
                            ))),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l.xSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
              ),
              fieldGap,
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l.xAll),
                    selected: _crop == null,
                    onSelected: (_) => setState(() => _crop = null),
                  ),
                  for (final c in Crop.values)
                    ChoiceChip(
                      label: Text(l.crop(c)),
                      selected: _crop == c.name,
                      onSelected: (_) => setState(() => _crop = c.name),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l.xType),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.xAll)),
                  for (final k in activityKinds)
                    DropdownMenuItem(
                      value: k,
                      child: Text(activityLabel(context, k)),
                    ),
                ],
                onChanged: (v) => setState(() => _kind = v),
              ),
              fieldGap,
              if (plots.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _plot,
                  decoration: InputDecoration(labelText: l.xPlot),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.xAll)),
                    for (final p in plots)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _plot = v),
                ),
                fieldGap,
              ],
              if (_range != null)
                Text(
                  '${context.fmt.date(_range!.start)} — ${context.fmt.date(_range!.end)}',
                ),
              if (entries.isEmpty)
                EmptyState(icon: Icons.menu_book_outlined, text: l.xEmpty),
              for (final v in entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(v.activity.title),
                    subtitle: Text(
                      '${context.fmt.date(v.activity.date)} · ${activityLabel(context, v.activity.kind)}',
                    ),
                    trailing: Text(context.fmt.money(v.total)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiaryDetail(v.activity.id),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DiaryDetail extends ConsumerWidget {
  const DiaryDetail(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final value = ref.watch(diaryProvider);
    final stock = ref.watch(stockBalancesProvider).value ?? [];
    final names = ref.watch(workerNamesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.xDiary)),
      body: AsyncBody(
        value: value,
        builder: (all) {
          final v = all.where((v) => v.activity.id == id).firstOrNull;
          if (v == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                v.activity.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${context.fmt.date(v.activity.date)} · ${activityLabel(context, v.activity.kind)} · ${v.activity.days} ${l.xDays}',
              ),
              const SizedBox(height: 12),
              Text(v.activity.notes),
              if (v.activity.remindOn != null)
                Text(
                  '${l.xRemindOn}: ${context.fmt.date(v.activity.remindOn!)}',
                ),
              SectionTitle(l.xInputsUsed),
              for (final i in v.inputs)
                ListTile(
                  title: Text(
                    stock
                            .where((s) => s.item.id == i.itemId)
                            .firstOrNull
                            ?.item
                            .name ??
                        l.xStock,
                  ),
                  subtitle: Text(formatQty(i.quantity)),
                  trailing: Text(context.fmt.money(i.cost)),
                ),
              SectionTitle(l.navLabour),
              for (final line in v.labour)
                ListTile(
                  title: Text(names[line.workerId] ?? l.xWorker),
                  subtitle: Text(
                    '${formatQty(line.quantity)} · ${l.unit(RateUnit.values.byName(line.unit))}',
                  ),
                  trailing: Text(context.fmt.money(line.amount)),
                ),
              KvRow(l.total, context.fmt.money(v.total)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(l.xDocuments),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DocumentsScreen(refType: 'activity', refId: id),
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DiaryForm(existing: v)),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(l.delete),
                onPressed: () async {
                  if (!await confirm(context, title: l.confirmDelete) ||
                      !context.mounted) {
                    return;
                  }
                  await perform(context, () async {
                    await ref.read(diaryRepositoryProvider).delete(id);
                    if (context.mounted) Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class DiaryForm extends ConsumerStatefulWidget {
  const DiaryForm({super.key, this.existing});
  final ActivityView? existing;
  @override
  ConsumerState<DiaryForm> createState() => _DiaryFormState();
}

class _DiaryFormState extends ConsumerState<DiaryForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _days = TextEditingController(text: '1');
  late DateTime _date;
  DateTime? _reminder;
  String _kind = 'fertiliser';
  Set<Crop> _crops = {};
  Set<String> _plots = {};
  final List<InputUse> _inputs = [];
  final List<LabourInput> _labour = [];
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _date = ref.read(entryDayProvider);
    final v = widget.existing;
    if (v != null) {
      _title.text = v.activity.title;
      _notes.text = v.activity.notes;
      _days.text = '${v.activity.days}';
      _date = v.activity.date;
      _reminder = v.activity.remindOn;
      _kind = v.activity.kind;
      _crops = v.activity.crops.map(Crop.values.byName).toSet();
      _plots = v.activity.plotIds.toSet();
      _inputs.addAll(v.inputs.map((i) => InputUse(i.itemId, i.quantity)));
      _labour.addAll(
        v.labour.map(
          (l) => LabourInput(
            workerId: l.workerId,
            qty: l.quantity,
            unit: RateUnit.values.byName(l.unit),
            rate: l.rate,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _input() async {
    final l = context.l;
    final stock = ref.read(stockBalancesProvider).value ?? [];
    if (stock.isEmpty) {
      showSnack(context, l.xStock);
      return;
    }
    await openEntryForm(
      context,
      title: l.xAddInput,
      fields: [
        EntryField(
          'item',
          l.xStockName,
          kind: InputKind.choice,
          required: true,
          options: {
            for (final s in stock) s.item.id: '${s.item.name} (${s.item.unit})',
          },
        ),
        EntryField(
          'quantity',
          l.xQuantity,
          kind: InputKind.quantity,
          required: true,
          positive: true,
        ),
      ],
      onSave: (v) async {
        setState(
          () => _inputs.add(InputUse(v.text('item'), v.number('quantity'))),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(diaryRepositoryProvider)
          .save(
            id: widget.existing?.activity.id,
            date: _date,
            kind: _kind,
            title: _title.text,
            days: int.parse(_days.text),
            crops: _crops.map((c) => c.name).toList(),
            plotIds: _plots.toList(),
            notes: _notes.text,
            remindOn: _reminder,
            inputs: _inputs,
            labour: _labour,
          );
      if (!mounted) return;
      if (widget.existing != null) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DiaryDetail(id)),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureText(context, error);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final plots = ref.watch(plotsProvider).value ?? [];
    final stock = ref.watch(stockBalancesProvider).value ?? [];
    final names = ref.watch(workerNamesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.xActivity)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ChoiceChips(
              values: activityKinds,
              selected: _kind,
              label: (k) => activityLabel(context, k),
              onSelected: (k) => setState(() => _kind = k),
            ),
            fieldGap,
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l.xTitle),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            fieldGap,
            DateField(
              label: l.date,
              value: _date,
              lastDate: ref.watch(todayProvider),
              onChanged: (v) => setState(() => _date = v),
            ),
            fieldGap,
            QtyField(
              controller: _days,
              label: l.xDays,
              required: true,
              decimals: false,
              validator: (v) {
                final n = int.tryParse(v);
                return n == null || n < 1 || n > 366 ? l.xInvalid : null;
              },
            ),
            fieldGap,
            FieldLabel(l.xCrop),
            MultiChoiceChips(
              values: Crop.values,
              selected: _crops,
              label: l.crop,
              onChanged: (v) => setState(() => _crops = v),
            ),
            fieldGap,
            FieldLabel(l.xPlot),
            MultiChoiceChips(
              values: plots.map((p) => p.id).toList(),
              selected: _plots,
              label: (id) => plots.firstWhere((p) => p.id == id).name,
              onChanged: (v) => setState(() => _plots = v),
            ),
            if (!v1 || _inputs.isNotEmpty) SectionTitle(l.xInputsUsed),
            for (var i = 0; i < _inputs.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  stock
                          .where((s) => s.item.id == _inputs[i].itemId)
                          .firstOrNull
                          ?.item
                          .name ??
                      l.xStock,
                ),
                subtitle: Text(formatQty(_inputs[i].quantity)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l.delete,
                  onPressed: () => setState(() => _inputs.removeAt(i)),
                ),
              ),
            if (!v1)
              OutlinedButton.icon(
                onPressed: _input,
                icon: const Icon(Icons.add),
                label: Text(l.xAddInput),
              ),
            SectionTitle(l.navLabour),
            for (var i = 0; i < _labour.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(names[_labour[i].workerId] ?? l.xWorker),
                subtitle: Text(
                  '${formatQty(_labour[i].qty)} · ${context.fmt.money(_labour[i].amount)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l.delete,
                  onPressed: () => setState(() => _labour.removeAt(i)),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.xAddLabour),
              onPressed: () async {
                final line = await showLabourLineSheet(
                  context,
                  unit: RateUnit.day,
                  qty: double.tryParse(_days.text),
                );
                if (line != null && context.mounted) {
                  if (line.workerId == null) {
                    showSnack(context, l.xWorker);
                    return;
                  }
                  setState(() => _labour.add(line));
                }
              },
            ),
            fieldGap,
            VoiceNotesField(controller: _notes),
            fieldGap,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.xAddReminder),
              value: _reminder != null,
              onChanged: (v) => setState(
                () =>
                    _reminder = v ? _date.add(const Duration(days: 40)) : null,
              ),
            ),
            if (_reminder != null)
              DateField(
                label: l.xRemindOn,
                value: _reminder!,
                onChanged: (v) => setState(() => _reminder = v),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.save),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
