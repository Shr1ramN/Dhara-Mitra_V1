import '../../../core/v1.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../common/forms.dart';

/// Sale of all or part of a lot (F4.8, F4.12).
class SaleFormScreen extends ConsumerWidget {
  const SaleFormScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.saleTitle)),
    body: AsyncBody(
      value: ref.watch(lotViewProvider(lotId)),
      builder: (v) => v == null ? const SizedBox.shrink() : _SaleForm(v),
    ),
  );
}

class _SaleForm extends ConsumerStatefulWidget {
  const _SaleForm(this.v);

  final LotView v;

  @override
  ConsumerState<_SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends ConsumerState<_SaleForm> {
  final _form = GlobalKey<FormState>();
  late DateTime _date = ref.read(entryDayProvider);
  Buyer? _buyer;
  bool _newBuyer = false;
  final _buyerName = TextEditingController();
  BuyerKind _buyerKind = BuyerKind.campco;
  late final Map<ArecaGrade, double> _left = {
    for (final MapEntry(:key, :value) in widget.v.remaining.entries)
      if (value > 0) key: value,
  };
  late final Map<ArecaGrade, TextEditingController> _kg = {
    for (final g in _left.keys)
      g: TextEditingController(
        text: _left.length == 1 ? qtyToInput(_left[g]) : '',
      ),
  };
  late final Map<ArecaGrade, TextEditingController> _rate = {
    for (final g in _left.keys) g: TextEditingController(),
  };
  final _deductions = TextEditingController();
  final _deductionNote = TextEditingController();
  final _received = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      ..._kg.values,
      ..._rate.values,
      _buyerName,
      _deductions,
      _deductionNote,
      _received,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<SaleLineInput> get _lines => [
    for (final g in _left.keys)
      if ((parseQty(_kg[g]!.text) ?? 0) > 0)
        SaleLineInput(
          grade: g,
          kg: parseQty(_kg[g]!.text)!,
          rate: parseRupees(_rate[g]!.text) ?? 0,
        ),
  ];

  int get _gross => _lines.fold(0, (s, x) => s + x.amount);

  int get _net => _gross - (parseRupees(_deductions.text) ?? 0);

  Future<void> _save() async {
    final l = context.l;
    if (!_form.currentState!.validate()) return;
    if (_lines.isEmpty) {
      showSnack(context, l.enterSomethingSold);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(lotsRepositoryProvider);
      await ref.read(databaseProvider).transaction(() async {
        final isNew =
            _newBuyer || (ref.read(buyersProvider).value ?? const []).isEmpty;
        final buyerId = isNew
            ? await repo.saveBuyer(name: _buyerName.text, kind: _buyerKind)
            : _buyer!.id;
        await repo.recordSale(
          lotId: widget.v.lot.id,
          buyerId: buyerId,
          date: _date,
          lines: _lines,
          deductions: parseRupees(_deductions.text) ?? 0,
          deductionNote: _deductionNote.text.trim(),
          received: parseRupees(_received.text) ?? 0,
        );
      });
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showSnack(context, failureText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final buyers = ref.watch(buyersProvider).value ?? const [];
    final newBuyer = _newBuyer || buyers.isEmpty;
    void refresh(String _) => setState(() {});

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(widget.v.lot.title, style: display(17)),
          Text(
            widget.v.lot.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          fieldGap,
          DateField(
            label: l.date,
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          fieldGap,
          if (!newBuyer)
            DropdownButtonFormField<Buyer>(
              initialValue: _buyer,
              decoration: InputDecoration(labelText: l.buyer),
              hint: Text(l.chooseBuyer),
              items: [
                for (final b in buyers)
                  DropdownMenuItem(value: b, child: Text(b.name)),
              ],
              validator: (b) => b == null ? l.requiredField : null,
              onChanged: (b) => setState(() => _buyer = b),
            )
          else ...[
            TextFormField(
              controller: _buyerName,
              decoration: InputDecoration(
                labelText: l.buyerName,
                hintText: l.buyerNameHint,
              ),
              validator: (t) =>
                  (t ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 10),
            ChoiceChips(
              values: BuyerKind.values,
              selected: _buyerKind,
              label: l.buyerKind,
              onSelected: (k) => setState(() => _buyerKind = k),
            ),
          ],
          if (buyers.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _newBuyer = !_newBuyer),
                icon: Icon(
                  _newBuyer ? Icons.list : Icons.person_add_alt,
                  size: 18,
                ),
                label: Text(_newBuyer ? l.chooseBuyer : l.newBuyer),
              ),
            ),
          SectionTitle(l.whatWasSold),
          for (final g in _left.keys) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: QtyField(
                    controller: _kg[g]!,
                    label: l.grade(g),
                    hint: l.kgLeft(formatQty(_left[g]!)),
                    suffix: l.kgUnit,
                    onChanged: refresh,
                    validator: (t) => (parseQty(t) ?? 0) > _left[g]! + 0.001
                        ? l.moreThanLeft(formatQty(_left[g]!))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MoneyField(
                    controller: _rate[g]!,
                    label: l.ratePerKg,
                    onChanged: refresh,
                    validator: (t) =>
                        (parseQty(_kg[g]!.text) ?? 0) > 0 &&
                            (parseRupees(t) ?? 0) <= 0
                        ? l.requiredField
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          fieldGap,
          MoneyField(
            controller: _deductions,
            label: l.deductions,
            hint: l.deductionsHint,
            onChanged: refresh,
          ),
          fieldGap,
          TextField(
            controller: _deductionNote,
            decoration: InputDecoration(labelText: l.deductionNote),
          ),
          fieldGap,
          MoneyField(
            controller: _received,
            label: l.receivedNow,
            onChanged: refresh,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  setState(() => _received.text = paiseToInput(_net)),
              child: Text(l.fullyPaid),
            ),
          ),
          const SizedBox(height: 6),
          PaddedCard(
            child: Column(
              children: [
                for (final x in _lines)
                  KvRow(
                    '${l.grade(x.grade)} · ${fmt.kg(x.kg)}',
                    fmt.money(lineAmount(x.kg, x.rate)),
                  ),
                KvRow(l.gross, fmt.money(_gross)),
                if ((parseRupees(_deductions.text) ?? 0) > 0)
                  KvRow(
                    l.deductions,
                    '− ${fmt.money(parseRupees(_deductions.text)!)}',
                  ),
                const Divider(),
                KvRow(l.net, fmt.money(_net)),
                KvRow(
                  l.pending,
                  fmt.money(
                    math.max(0, _net - (parseRupees(_received.text) ?? 0)),
                  ),
                  valueColor: AppColors.warnText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.save)),
        ],
      ),
    );
  }
}
