import '../../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/season.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/lots_repository.dart';
import 'lot_sheets.dart';
import '../../common/forms.dart';

/// New areca harvest round (F4.1–F4.3).
class HarvestFormScreen extends ConsumerStatefulWidget {
  const HarvestFormScreen({super.key});

  @override
  ConsumerState<HarvestFormScreen> createState() => _HarvestFormScreenState();
}

class _HarvestFormScreenState extends ConsumerState<HarvestFormScreen> {
  final _form = GlobalKey<FormState>();
  late DateTime _date = ref.read(entryDayProvider);
  Set<String> _plotIds = {};
  final _palms = TextEditingController();
  final _freshKg = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final List<LabourInput> _labour = [];
  bool _titleEdited = false;
  bool _saving = false;
  String _mode = 'bags';

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).setting('harvest_unit').then((unit) {
      if (mounted && unit != null) setState(() => _mode = unit);
    });
  }

  @override
  void dispose() {
    _palms.dispose();
    _freshKg.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _suggestedTitle(AppLocalizations l) {
    final startMonth = ref.read(farmProvider).value?.seasonStartMonth ?? 6;
    final season = Season.of(_date, startMonth: startMonth);
    final round =
        (ref.read(lotViewsProvider).value ?? const [])
            .where((v) => v.lot.crop == Crop.areca && v.season == season)
            .length +
        1;
    final plots = (ref.read(plotsProvider).value ?? const [])
        .where((p) => _plotIds.contains(p.id))
        .map((p) => p.name);
    return [l.harvestRound(round), ...plots].join(' · ');
  }

  void _refreshTitle() {
    if (!_titleEdited) _title.text = _suggestedTitle(context.l);
  }

  Future<void> _addLabour() async {
    final line = await showLabourLineSheet(
      context,
      unit: RateUnit.palm,
      qty: parseQty(_palms.text),
      preferRole: WorkerRole.climber,
    );
    if (line != null) setState(() => _labour.add(line));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(lotsRepositoryProvider)
          .createHarvestLot(
            crop: Crop.areca,
            harvestedOn: _date,
            title: _title.text.trim().isEmpty
                ? _suggestedTitle(context.l)
                : _title.text,
            plotIds: _plotIds.toList(),
            palmsClimbed: parseQty(_palms.text)?.round(),
            freshKg: _mode == 'kg' ? parseQty(_freshKg.text) : null,
            freshBags: _mode == 'bags' ? parseQty(_freshKg.text) : null,
            quantityMode: _mode,
            seasonStartMonth:
                ref.read(farmProvider).value?.seasonStartMonth ?? 6,
            notes: _notes.text.trim(),
            labour: _labour,
          );
      await ref.read(databaseProvider).putSetting('harvest_unit', _mode);
      if (mounted) context.pushReplacement('/lot/$id');
    } catch (error) {
      if (mounted) showSnack(context, failureText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final plots = ref.watch(plotsProvider).value ?? const [];
    final names = ref.watch(workerNamesProvider);
    final labourTotal = _labour.fold(0, (s, x) => s + x.amount);
    if (_title.text.isEmpty && !_titleEdited) _title.text = _suggestedTitle(l);

    return Scaffold(
      appBar: AppBar(title: Text(l.harvestTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            DateField(
              label: l.harvestDate,
              value: _date,
              lastDate: ref.read(todayProvider),
              onChanged: (d) => setState(() {
                _date = d;
                _refreshTitle();
              }),
            ),
            fieldGap,
            FieldLabel(l.fQuantityMode),
            ChoiceChips(
              values: const ['bags', 'kg'],
              selected: _mode,
              label: (u) => u == 'bags' ? l.fBagsMode : l.fKgMode,
              onSelected: (u) => setState(() {
                _mode = u;
                _freshKg.clear();
              }),
            ),
            fieldGap,
            FieldLabel(l.whichPlots),
            MultiChoiceChips(
              values: [for (final p in plots) p.id],
              selected: _plotIds,
              label: (id) => plots.firstWhere((p) => p.id == id).name,
              onChanged: (s) => setState(() {
                _plotIds = s;
                _refreshTitle();
              }),
            ),
            fieldGap,
            Row(
              children: [
                Expanded(
                  child: QtyField(
                    controller: _palms,
                    label: l.palmsClimbed,
                    decimals: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QtyField(
                    controller: _freshKg,
                    label: _mode == 'bags' ? l.fFreshBags : l.freshKg,
                    hint: l.optional,
                  ),
                ),
              ],
            ),
            fieldGap,
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l.lotTitle,
                hintText: l.lotTitleHint,
              ),
              onChanged: (_) => _titleEdited = true,
            ),
            SectionTitle(
              l.labourSection,
              trailing: TextButton.icon(
                onPressed: _addLabour,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.addLabourLine),
              ),
            ),
            PaddedCard(
              child: _labour.isEmpty
                  ? Text(
                      l.noLabour,
                      style: const TextStyle(color: AppColors.textMuted),
                    )
                  : Column(
                      children: [
                        for (final (i, x) in _labour.indexed)
                          LabourLineTile(
                            name: names[x.workerId] ?? '',
                            qty: x.qty,
                            unit: x.unit,
                            rate: x.rate,
                            amount: x.amount,
                            onRemove: () => setState(() => _labour.removeAt(i)),
                          ),
                        const Divider(),
                        KvRow(l.labourCost, formatRupees(labourTotal)),
                      ],
                    ),
            ),
            fieldGap,
            TextField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.notes),
              maxLines: 2,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
