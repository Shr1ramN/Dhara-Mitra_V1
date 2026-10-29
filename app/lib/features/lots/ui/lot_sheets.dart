import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../common/forms.dart';
import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/lots_repository.dart';
import '../domain/lot_calc.dart';
import '../domain/lot_view.dart';
import '../../labour/ui/worker_rates_screen.dart';

/// One worker's line on a lot: qty × rate (F4.3, F4.5).
Future<LabourInput?> showLabourLineSheet(
  BuildContext context, {
  RateUnit unit = RateUnit.day,
  double? qty,
  WorkerRole? preferRole,
}) => showFormSheet<LabourInput>(
  context,
  title: context.l.addLabourLine,
  builder: (_) => _LabourLineForm(unit: unit, qty: qty, preferRole: preferRole),
);

class _LabourLineForm extends ConsumerStatefulWidget {
  const _LabourLineForm({required this.unit, this.qty, this.preferRole});

  final RateUnit unit;
  final double? qty;
  final WorkerRole? preferRole;

  @override
  ConsumerState<_LabourLineForm> createState() => _LabourLineFormState();
}

class _LabourLineFormState extends ConsumerState<_LabourLineForm> {
  final _form = GlobalKey<FormState>();
  late final _qty = TextEditingController(text: qtyToInput(widget.qty));
  final _rate = TextEditingController();
  late RateUnit _unit = widget.unit;
  Worker? _worker;

  @override
  void dispose() {
    _qty.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _prefillRate() {
    final w = _worker;
    if (w == null) return;
    final rate = _unit == RateUnit.day
        ? w.dayRate
        : (w.pieceUnit == _unit ? w.pieceRate : null);
    if (rate != null && rate > 0) _rate.text = paiseToInput(rate);
  }

  int get _amount =>
      lineAmount(parseQty(_qty.text) ?? 0, parseRupees(_rate.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final savedRates = _worker == null
        ? const <WorkerRate>[]
        : (ref.watch(workerRatesProvider(_worker!.id)).value ??
              const <WorkerRate>[]);
    final workers = (ref.watch(workerSummariesProvider).value ?? const [])
        .map((s) => s.worker)
        .where((w) => w.active)
        .toList();
    if (widget.preferRole != null) {
      workers.sort(
        (a, b) =>
            (b.roles.contains(widget.preferRole) ? 1 : 0) -
            (a.roles.contains(widget.preferRole) ? 1 : 0),
      );
    }
    if (workers.isEmpty) {
      return Text(
        l.noWorkersYet,
        style: const TextStyle(color: AppColors.textMuted),
      );
    }
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Worker>(
            initialValue: _worker,
            decoration: InputDecoration(labelText: l.worker),
            hint: Text(l.chooseWorker),
            items: [
              for (final w in workers)
                DropdownMenuItem(value: w, child: Text(w.name)),
            ],
            validator: (w) => w == null ? l.requiredField : null,
            onChanged: (w) => setState(() {
              _worker = w;
              if (w?.pieceUnit != null &&
                  _unit != RateUnit.day &&
                  _unit != w!.pieceUnit) {
                _unit = w.pieceUnit!;
              }
              _prefillRate();
            }),
          ),
          fieldGap,
          FieldLabel(l.unitLabel),
          if (savedRates.any((r) => !r.deleted)) ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_worker?.id),
              decoration: InputDecoration(labelText: l.xType),
              items: [
                for (final r in savedRates.where((r) => !r.deleted))
                  DropdownMenuItem(
                    value: r.id,
                    child: Text('${r.work} · ${formatRupees(r.rate)}'),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                final rate = savedRates.firstWhere((r) => r.id == id);
                setState(() {
                  _unit = RateUnit.values.byName(rate.unit);
                  _rate.text = paiseToInput(rate.rate);
                });
              },
            ),
            fieldGap,
          ],
          if (_unit == RateUnit.day) Text(l.wDailyHint),
          ChoiceChips(
            values: RateUnit.values,
            selected: _unit,
            label: l.unit,
            onSelected: (u) => setState(() {
              _unit = u;
              if (u == RateUnit.lump) _qty.text = '1';
              _prefillRate();
            }),
          ),
          fieldGap,
          Row(
            children: [
              Expanded(
                child: QtyField(
                  controller: _qty,
                  label: l.quantity,
                  suffix: l.unit(_unit),
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MoneyField(
                  controller: _rate,
                  label: l.rateRupees,
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          KvRow(l.amount, formatRupees(_amount)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(
                context,
                LabourInput(
                  workerId: _worker!.id,
                  qty: parseQty(_qty.text)!,
                  unit: _unit,
                  rate: parseRupees(_rate.text)!,
                ),
              );
            },
            child: Text(l.add),
          ),
        ],
      ),
    );
  }
}

/// Line showing a labour entry with the worker's name.
class LabourLineTile extends StatelessWidget {
  const LabourLineTile({
    super.key,
    required this.name,
    required this.qty,
    required this.unit,
    required this.rate,
    required this.amount,
    this.onRemove,
  });

  final String name;
  final double qty;
  final RateUnit unit;
  final int rate;
  final int amount;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${formatQty(qty)} ${l.unit(unit)} × ${formatRupees(rate, showPaise: true)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupees(amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showStartDryingSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.startDrying,
      builder: (_) => _StartDryingForm(v),
    );

class _StartDryingForm extends ConsumerStatefulWidget {
  const _StartDryingForm(this.v);

  final LotView v;

  @override
  ConsumerState<_StartDryingForm> createState() => _StartDryingFormState();
}

class _StartDryingFormState extends ConsumerState<_StartDryingForm> {
  late DateTime _on = addDays(widget.v.lot.harvestedOn, 1).isAfter(today())
      ? today()
      : addDays(widget.v.lot.harvestedOn, 1);
  late final _yard = TextEditingController(text: widget.v.lot.yard);
  final _days = TextEditingController(text: '$defaultDryingDays');

  @override
  void dispose() {
    _yard.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateField(
          label: l.started,
          value: _on,
          onChanged: (d) => setState(() => _on = d),
        ),
        fieldGap,
        TextField(
          controller: _yard,
          decoration: InputDecoration(labelText: l.yard, hintText: l.yardHint),
        ),
        fieldGap,
        QtyField(controller: _days, label: l.targetDays, decimals: false),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            await ref
                .read(lotsRepositoryProvider)
                .startDrying(
                  widget.v.lot.id,
                  on: _on,
                  yard: _yard.text,
                  targetDays:
                      parseQty(_days.text)?.round() ?? defaultDryingDays,
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.startDrying),
        ),
      ],
    );
  }
}

Future<void> showFinishDryingSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.finishDrying,
      builder: (_) => _FinishDryingForm(v),
    );

class _FinishDryingForm extends ConsumerStatefulWidget {
  const _FinishDryingForm(this.v);

  final LotView v;

  @override
  ConsumerState<_FinishDryingForm> createState() => _FinishDryingFormState();
}

class _FinishDryingFormState extends ConsumerState<_FinishDryingForm> {
  final _form = GlobalKey<FormState>();
  DateTime _on = today();
  late final _dried = TextEditingController(
    text: qtyToInput(
      widget.v.lot.quantityMode == 'bags'
          ? widget.v.lot.driedBags
          : widget.v.lot.driedKg,
    ),
  );

  @override
  void dispose() {
    _dried.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateField(
            label: l.finished,
            value: _on,
            lastDate: ref.read(todayProvider),
            onChanged: (d) => setState(() => _on = d),
          ),
          fieldGap,
          QtyField(
            controller: _dried,
            label: widget.v.lot.quantityMode == 'bags'
                ? l.fDriedBags
                : l.driedKg,
            hint: l.optional,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              if (_on.isBefore(
                widget.v.lot.dryingStartedOn ?? widget.v.lot.harvestedOn,
              )) {
                showSnack(context, l.xInvalid);
                return;
              }
              await ref
                  .read(lotsRepositoryProvider)
                  .finishDrying(
                    widget.v.lot.id,
                    on: _on,
                    driedBags: widget.v.lot.quantityMode == 'bags'
                        ? parseQty(_dried.text)
                        : null,
                    driedKg: widget.v.lot.quantityMode == 'kg'
                        ? parseQty(_dried.text)
                        : null,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

Future<void> showPeelingSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.recordPeeling,
      builder: (_) => _PeelingForm(v),
    );

class _PeelingForm extends ConsumerStatefulWidget {
  const _PeelingForm(this.v);

  final LotView v;

  @override
  ConsumerState<_PeelingForm> createState() => _PeelingFormState();
}

class _PeelingFormState extends ConsumerState<_PeelingForm> {
  final _form = GlobalKey<FormState>();
  late DateTime _on = widget.v.lot.peeledOn ?? today();
  late final _dried = TextEditingController(
    text: qtyToInput(
      widget.v.lot.quantityMode == 'bags'
          ? widget.v.lot.driedBags
          : widget.v.lot.driedKg,
    ),
  );
  late final _chali = TextEditingController(
    text: qtyToInput(widget.v.lot.chaliKg),
  );
  late final _measured = TextEditingController(
    text: qtyToInput(widget.v.lot.driedKg),
  );
  final List<LabourInput> _peelers = [];

  @override
  void dispose() {
    _dried.dispose();
    _chali.dispose();
    _measured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final names = ref.watch(workerNamesProvider);
    final outTurn = outTurnPercent(
      driedKg: widget.v.lot.quantityMode == 'kg'
          ? parseQty(_dried.text)
          : parseQty(_measured.text),
      chaliKg: parseQty(_chali.text),
    );
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateField(
            label: l.date,
            value: _on,
            lastDate: ref.read(todayProvider),
            onChanged: (d) => setState(() => _on = d),
          ),
          fieldGap,
          Row(
            children: [
              Expanded(
                child: QtyField(
                  controller: _dried,
                  label: widget.v.lot.quantityMode == 'bags'
                      ? l.fDriedBags
                      : l.driedKg,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QtyField(
                  controller: _chali,
                  label: l.chaliKg,
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (widget.v.lot.quantityMode == 'bags')
            ExpansionTile(
              title: Text(l.driedKg),
              subtitle: Text(l.optional),
              children: [
                QtyField(
                  controller: _measured,
                  label: l.driedKg,
                  hint: l.optional,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          if (outTurn != null) KvRow(l.outTurn, fmt.percent(outTurn)),
          SectionTitle(
            l.peelers,
            trailing: TextButton.icon(
              onPressed: () async {
                final line = await showLabourLineSheet(
                  context,
                  unit: RateUnit.kg,
                  preferRole: WorkerRole.peeler,
                );
                if (line != null) setState(() => _peelers.add(line));
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addLabourLine),
            ),
          ),
          for (final (i, p) in _peelers.indexed)
            LabourLineTile(
              name: names[p.workerId] ?? '',
              qty: p.qty,
              unit: p.unit,
              rate: p.rate,
              amount: p.amount,
              onRemove: () => setState(() => _peelers.removeAt(i)),
            ),
          if (_peelers.isNotEmpty)
            KvRow(
              l.peelingCost,
              formatRupees(_peelers.fold(0, (s, p) => s + p.amount)),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              if (_on.isBefore(
                widget.v.lot.dryingEndedOn ?? widget.v.lot.harvestedOn,
              )) {
                showSnack(context, l.xInvalid);
                return;
              }
              await perform(context, () async {
                await ref
                    .read(lotsRepositoryProvider)
                    .recordPeeling(
                      widget.v.lot.id,
                      on: _on,
                      chaliKg: parseQty(_chali.text)!,
                      driedBags: widget.v.lot.quantityMode == 'bags'
                          ? parseQty(_dried.text)
                          : null,
                      driedKg: widget.v.lot.quantityMode == 'kg'
                          ? parseQty(_dried.text)
                          : parseQty(_measured.text),
                      peelers: _peelers,
                    );
                if (context.mounted) Navigator.pop(context);
              });
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

Future<void> showGradesSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.enterGrades,
      builder: (_) => _GradesForm(v),
    );

class _GradesForm extends ConsumerStatefulWidget {
  const _GradesForm(this.v);

  final LotView v;

  @override
  ConsumerState<_GradesForm> createState() => _GradesFormState();
}

class _GradesFormState extends ConsumerState<_GradesForm> {
  late final Map<ArecaGrade, TextEditingController> _kg = {
    for (final g in ArecaGrade.values)
      g: TextEditingController(text: qtyToInput(widget.v.gradeKg[g])),
  };

  @override
  void dispose() {
    for (final c in _kg.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final total = _kg.values.fold(0.0, (s, c) => s + (parseQty(c.text) ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in ArecaGrade.values) ...[
          QtyField(
            controller: _kg[g]!,
            label: l.grade(g),
            suffix: l.kgUnit,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
        ],
        KvRow(
          l.gradedTotal,
          widget.v.lot.chaliKg == null
              ? fmt.kg(total)
              : '${fmt.kg(total)} / ${fmt.kg(widget.v.lot.chaliKg!)}',
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () async {
            await ref.read(lotsRepositoryProvider).setGrades(widget.v.lot.id, {
              for (final MapEntry(:key, :value) in _kg.entries)
                key: parseQty(value.text) ?? 0,
            });
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

Future<void> showStorageSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.moveToStorage,
      builder: (_) => _StorageForm(v),
    );

class _StorageForm extends ConsumerStatefulWidget {
  const _StorageForm(this.v);

  final LotView v;

  @override
  ConsumerState<_StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends ConsumerState<_StorageForm> {
  late DateTime _on = widget.v.lot.storedOn ?? today();
  late final _place = TextEditingController(text: widget.v.lot.storagePlace);
  late final _bags = TextEditingController(
    text: widget.v.lot.bags?.toString() ?? '',
  );
  late final _price = TextEditingController(
    text: paiseToInput(widget.v.lot.storedPricePerKg),
  );

  @override
  void dispose() {
    _place.dispose();
    _bags.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateField(
          label: l.storedSince,
          value: _on,
          onChanged: (d) => setState(() => _on = d),
        ),
        fieldGap,
        TextField(
          controller: _place,
          decoration: InputDecoration(
            labelText: l.storagePlace,
            hintText: l.storagePlaceHint,
          ),
        ),
        fieldGap,
        Row(
          children: [
            Expanded(
              child: QtyField(
                controller: _bags,
                label: l.bags,
                decimals: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MoneyField(controller: _price, label: l.priceWhenStored),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            await ref
                .read(lotsRepositoryProvider)
                .store(
                  widget.v.lot.id,
                  on: _on,
                  place: _place.text,
                  bags: parseQty(_bags.text)?.round(),
                  pricePerKg: parseRupees(_price.text),
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// Moisture / pest check or a free note on the lot (F4.7).
Future<void> showCheckSheet(BuildContext context, LotView v) =>
    showFormSheet<void>(
      context,
      title: context.l.logCheck,
      builder: (_) => _CheckForm(v),
    );

class _CheckForm extends ConsumerStatefulWidget {
  const _CheckForm(this.v);

  final LotView v;

  @override
  ConsumerState<_CheckForm> createState() => _CheckFormState();
}

class _CheckFormState extends ConsumerState<_CheckForm> {
  LotEventKind _kind = LotEventKind.moisture;
  final _value = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(l.checkKind),
        ChoiceChips(
          values: const [
            LotEventKind.moisture,
            LotEventKind.pest,
            LotEventKind.note,
          ],
          selected: _kind,
          label: l.eventKind,
          onSelected: (k) => setState(() => _kind = k),
        ),
        fieldGap,
        if (_kind != LotEventKind.note) ...[
          TextField(
            controller: _value,
            decoration: InputDecoration(
              labelText: l.checkValue,
              hintText: l.checkValueHint,
            ),
          ),
          fieldGap,
        ],
        TextField(
          controller: _note,
          decoration: InputDecoration(labelText: l.note),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            await ref
                .read(lotsRepositoryProvider)
                .addEvent(
                  widget.v.lot.id,
                  _kind,
                  value: _value.text.trim(),
                  note: _note.text.trim(),
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

Future<void> showReceivedSheet(BuildContext context, SaleView s) =>
    showFormSheet<void>(
      context,
      title: context.l.updateReceived,
      builder: (_) => _ReceivedForm(s),
    );

class _ReceivedForm extends ConsumerStatefulWidget {
  const _ReceivedForm(this.s);

  final SaleView s;

  @override
  ConsumerState<_ReceivedForm> createState() => _ReceivedFormState();
}

class _ReceivedFormState extends ConsumerState<_ReceivedForm> {
  late final _received = TextEditingController(
    text: paiseToInput(widget.s.sale.received),
  );

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KvRow(l.net, formatRupees(widget.s.net)),
        const SizedBox(height: 8),
        MoneyField(controller: _received, label: l.received),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _received.text = paiseToInput(widget.s.net),
            child: Text(l.fullyPaid),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () async {
            await ref
                .read(lotsRepositoryProvider)
                .setReceived(
                  widget.s.sale.id,
                  parseRupees(_received.text) ?? 0,
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
