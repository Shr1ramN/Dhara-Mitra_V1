import '../../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';

/// Pay a worker or give an advance (F3.4, F3.5).
Future<void> showPaymentSheet(
  BuildContext context, {
  required Worker worker,
  required TxnKind kind,
  int? suggested,
}) {
  final l = context.l;
  return showFormSheet<void>(
    context,
    title:
        '${kind == TxnKind.advance ? l.advance : l.payment} · ${worker.name}',
    builder: (_) =>
        _PaymentForm(worker: worker, kind: kind, suggested: suggested),
  );
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({
    required this.worker,
    required this.kind,
    this.suggested,
  });

  final Worker worker;
  final TxnKind kind;
  final int? suggested;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: (widget.suggested ?? 0) > 0 ? paiseToInput(widget.suggested) : '',
  );
  final _note = TextEditingController();
  late DateTime _date = ref.read(entryDayProvider);
  PayMode _mode = PayMode.cash;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(labourRepositoryProvider)
        .addPayment(
          workerId: widget.worker.id,
          date: _date,
          kind: widget.kind,
          amount: parseRupees(_amount.text)!,
          mode: _mode,
          note: _note.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyField(
            controller: _amount,
            label: l.amountRupees,
            required: true,
            validator: (t) =>
                (parseRupees(t) ?? 0) <= 0 ? l.invalidNumber : null,
          ),
          fieldGap,
          DateField(
            label: l.date,
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          fieldGap,
          FieldLabel(l.paidBy),
          ChoiceChips(
            values: PayMode.values,
            selected: _mode,
            label: l.payMode,
            onSelected: (m) => setState(() => _mode = m),
          ),
          fieldGap,
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.note),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}
