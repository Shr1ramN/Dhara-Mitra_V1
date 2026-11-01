import '../../../core/widgets.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/form_fields.dart';
import '../../../core/indian_phone.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/v1.dart';
import '../../common/forms.dart';
import 'saved_tick.dart';

class SimpleWorkerForm extends ConsumerStatefulWidget {
  const SimpleWorkerForm({super.key, this.workerId});
  final String? workerId;
  @override
  ConsumerState<SimpleWorkerForm> createState() => _SimpleWorkerState();
}

class _SimpleWorkerState extends ConsumerState<SimpleWorkerForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      rate = TextEditingController(),
      half = TextEditingController();
  String type = 'daily';
  bool loading = true, saving = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final w = widget.workerId == null
        ? null
        : await ref.read(labourRepositoryProvider).getWorker(widget.workerId!);
    if (!mounted) return;
    if (w != null) {
      name.text = w.name;
      phone.text = w.phone;
      rate.text = paiseToInput(w.dayRate);
      half.text = w.halfDayRate == null ? '' : paiseToInput(w.halfDayRate!);
      type = w.wageType;
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    for (final c in [name, phone, rate, half]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref
          .read(labourRepositoryProvider)
          .saveWorker(
            WorkersCompanion(
              id: widget.workerId == null
                  ? const Value.absent()
                  : Value(widget.workerId!),
              name: Value(name.text.trim()),
              phone: Value(
                phone.text.trim().isEmpty ? '' : indianPhone(phone.text)!,
              ),
              wageType: Value(type),
              dayRate: Value(type == 'daily' ? parseRupees(rate.text)! : 0),
              halfDayRate: Value(
                type == 'daily' ? parseRupees(half.text) : null,
              ),
            ),
          );
      if (mounted) {
        showSavedTick(context, context.l.workerSaved);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workerId == null ? l.addWorker : l.editWorker),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(labelText: l.workerName),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l.requiredField : null,
                  ),
                  fieldGap,
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.phone),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty || indianPhone(v!) != null
                        ? null
                        : l.fMobileError,
                  ),
                  fieldGap,
                  Text(v1Text(context, 'Worker type', 'ಕಾರ್ಮಿಕರ ವಿಧ')),
                  RadioGroup<String>(
                    groupValue: type,
                    onChanged: (v) => setState(() => type = v!),
                    child: Column(
                      children: [
                        RadioListTile(
                          value: 'daily',
                          title: Text(v1Text(context, 'Daily wage', 'ದಿನಗೂಲಿ')),
                        ),
                        RadioListTile(
                          value: 'other',
                          title: Text(
                            v1Text(
                              context,
                              'Other — enter wage each day',
                              'ಇತರೆ — ಪ್ರತಿ ದಿನದ ಕೂಲಿ ನಮೂದಿಸಿ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (type == 'daily') ...[
                    MoneyField(
                      controller: rate,
                      label: l.dayRate,
                      required: true,
                      validator: (v) =>
                          (parseRupees(v) ?? 0) <= 0 ? l.invalidNumber : null,
                    ),
                    fieldGap,
                    MoneyField(
                      controller: half,
                      label: l.halfDayRate,
                      hint: l.halfDayHint,
                    ),
                  ] else
                    Text(
                      v1Text(
                        context,
                        'Enter the actual wage for each present or half day in attendance.',
                        'ಹಾಜರಾತಿಯಲ್ಲಿ ಪೂರ್ಣ ಅಥವಾ ಅರ್ಧ ದಿನಕ್ಕೆ ನಿಜವಾದ ಕೂಲಿಯನ್ನು ನಮೂದಿಸಿ.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(l.save),
                  ),
                ],
              ),
            ),
    );
  }
}
