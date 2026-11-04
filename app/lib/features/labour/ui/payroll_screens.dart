import '../../../core/draft_guard.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/v1.dart';
import '../../../core/widgets.dart';
import '../../common/forms.dart';
import '../data/payroll_repository.dart';
import 'saved_tick.dart';

class PayrollData {
  PayrollData(this.txns, this.loans, this.settlements, this.attendance);
  final List<WorkerTxn> txns;
  final List<WorkerLoanEntry> loans;
  final List<WorkerSettlement> settlements;
  final List<AttendanceEntry> attendance;
  int available(String id, DateTime end) => txns
      .where((e) => e.workerId == id)
      .fold(
        0,
        (s, e) =>
            s +
            (e.kind == TxnKind.work
                ? (e.date.isAfter(end) ? 0 : e.amount)
                : -e.amount),
      );
  int due(String id, DateTime end) => txns
      .where((e) => e.workerId == id && !e.date.isAfter(end))
      .fold(0, (s, e) => s + (e.kind == TxnKind.work ? e.amount : -e.amount));
  int loan(String id, DateTime end) => loans
      .where((e) => e.workerId == id && !e.date.isAfter(end))
      .fold(
        0,
        (s, e) =>
            s + (['previous', 'new'].contains(e.kind) ? e.amount : -e.amount),
      );
}

final payrollDataProvider = StreamProvider<PayrollData>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAll(
    [
      db.workerTxns,
      db.workerLoanEntries,
      db.workerSettlements,
      db.attendanceEntries,
    ],
    () async => PayrollData(
      (await db.select(db.workerTxns).get()).where((e) => !e.deleted).toList(),
      (await db.select(db.workerLoanEntries).get())
          .where((e) => !e.deleted)
          .toList(),
      (await db.select(db.workerSettlements).get())
          .where((e) => !e.deleted)
          .toList(),
      (await db.select(db.attendanceEntries).get())
          .where((e) => !e.deleted)
          .toList(),
    ),
  );
});

String loanKind(BuildContext context, String kind) => switch (kind) {
  'previous' => context.l.previousWorkerLoan,
  'new' => context.l.newWorkerLoan,
  'deduction' => v1Text(context, 'Deducted from wages', 'ಕೂಲಿಯಿಂದ ಕಡಿತ'),
  _ => context.l.workerLoanRepayment,
};

class WorkerLoanForm extends ConsumerStatefulWidget {
  const WorkerLoanForm({
    super.key,
    required this.worker,
    this.repayment = false,
  });
  final Worker worker;
  final bool repayment;
  @override
  ConsumerState<WorkerLoanForm> createState() => _WorkerLoanState();
}

class _WorkerLoanState extends ConsumerState<WorkerLoanForm> {
  final form = GlobalKey<FormState>(),
      amount = TextEditingController(),
      note = TextEditingController();
  late DateTime date = dateOnly(ref.read(entryDayProvider));
  String kind = 'new';
  bool busy = false;
  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await PayrollRepository(ref.read(databaseProvider)).loan(
        workerId: widget.worker.id,
        date: date,
        kind: widget.repayment ? 'repayment' : kind,
        amount: parseRupees(amount.text)!,
        note: note.text.trim(),
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
    final p = ref.watch(payrollDataProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(widget.worker.name)),
      body: DraftGuard(
        controllers: [amount, note],
        extra: () => [date.toIso8601String(), kind],
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.repayment
                    ? loanKind(context, 'repayment')
                    : context.l.workerLoan,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (p != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${context.l.workerLoanOutstanding}: ${context.fmt.money(p.loan(widget.worker.id, dateOnly(DateTime.now())))}',
                  ),
                ),
              if (!widget.repayment)
                RadioGroup<String>(
                  groupValue: kind,
                  onChanged: (v) => setState(() => kind = v!),
                  child: Column(
                    children: [
                      for (final k in ['previous', 'new'])
                        RadioListTile(
                          value: k,
                          title: Text(loanKind(context, k)),
                        ),
                    ],
                  ),
                ),
              MoneyField(
                controller: amount,
                label: l.amountRupees,
                required: true,
                validator: (v) =>
                    (parseRupees(v) ?? 0) <= 0 ? l.invalidNumber : null,
              ),
              fieldGap,
              DateField(
                label: l.date,
                value: date,
                onChanged: (v) => setState(() => date = v),
              ),
              fieldGap,
              Text(
                v1Text(
                  context,
                  'Use the date the loan was given. Future-work loans are recorded when the money is given.',
                  'ಸಾಲ ನೀಡಿದ ದಿನಾಂಕವನ್ನು ಬಳಸಿ. ಮುಂದಿನ ಕೆಲಸದ ಸಾಲವನ್ನು ಹಣ ನೀಡಿದಾಗ ದಾಖಲಿಸಿ.',
                ),
              ),
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: l.note),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: busy ? null : save, child: Text(l.save)),
            ],
          ),
        ),
      ),
    );
  }
}

class SettlementForm extends ConsumerStatefulWidget {
  const SettlementForm({super.key, required this.worker});
  final Worker worker;
  @override
  ConsumerState<SettlementForm> createState() => _SettlementState();
}

class _SettlementState extends ConsumerState<SettlementForm> {
  final form = GlobalKey<FormState>(),
      cash = TextEditingController(),
      deduction = TextEditingController(),
      note = TextEditingController();
  late DateTime end = dateOnly(ref.read(entryDayProvider));
  late DateTime start = end.subtract(Duration(days: end.weekday - 1));
  late DateTime paidOn = end;
  PayMode mode = PayMode.cash;
  bool busy = false;
  @override
  void dispose() {
    for (final c in [cash, deduction, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await PayrollRepository(ref.read(databaseProvider)).settle(
        workerId: widget.worker.id,
        date: paidOn,
        start: start,
        end: end,
        cashPaid: parseRupees(cash.text) ?? 0,
        deduction: parseRupees(deduction.text) ?? 0,
        mode: mode,
        note: note.text.trim(),
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
    final p = ref.watch(payrollDataProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l.settleWages)),
      body: AsyncBody(
        value: p,
        builder: (data) {
          final id = widget.worker.id;
          bool inPeriod(DateTime date) =>
              !date.isBefore(start) && !date.isAfter(end);
          final entries = data.attendance.where(
            (e) => e.workerId == id && inPeriod(e.date),
          );
          final earned = data.txns
              .where(
                (e) =>
                    e.workerId == id &&
                    e.kind == TxnKind.work &&
                    inPeriod(e.date),
              )
              .fold<int>(0, (s, e) => s + e.amount);
          return DraftGuard(
            controllers: [cash, deduction, note],
            extra: () => [
              start.toIso8601String(),
              end.toIso8601String(),
              paidOn.toIso8601String(),
              mode.name,
            ],
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.worker.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  fieldGap,
                  DateField(
                    label: v1Text(context, 'Period from', 'ಅವಧಿ ಆರಂಭ'),
                    value: start,
                    onChanged: (d) => setState(() => start = dateOnly(d)),
                  ),
                  fieldGap,
                  DateField(
                    label: v1Text(context, 'Period to', 'ಅವಧಿ ಅಂತ್ಯ'),
                    value: end,
                    onChanged: (d) => setState(() => end = dateOnly(d)),
                  ),
                  fieldGap,
                  PaddedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KvRow(
                          l.present,
                          '${entries.where((e) => e.status == AttendanceStatus.present).length}',
                        ),
                        KvRow(
                          l.attendance(AttendanceStatus.half),
                          '${entries.where((e) => e.status == AttendanceStatus.half).length}',
                        ),
                        KvRow(
                          v1Text(
                            context,
                            'Wages earned in period',
                            'ಈ ಅವಧಿಯ ಗಳಿಕೆ',
                          ),
                          context.fmt.money(earned),
                        ),
                        KvRow(
                          v1Text(
                            context,
                            'Opening unpaid balance',
                            'ಆರಂಭಿಕ ಬಾಕಿ',
                          ),
                          context.fmt.money(
                            data.due(
                              id,
                              start.subtract(const Duration(days: 1)),
                            ),
                          ),
                        ),
                        KvRow(
                          v1Text(
                            context,
                            'Unpaid through period end',
                            'ಅವಧಿ ಅಂತ್ಯದ ಬಾಕಿ',
                          ),
                          context.fmt.money(data.due(id, end)),
                        ),
                        KvRow(
                          v1Text(
                            context,
                            'Available to settle now',
                            'ಈಗ ಪಾವತಿಸಬಹುದಾದ ಮೊತ್ತ',
                          ),
                          context.fmt.money(
                            data.available(id, end).clamp(0, 1 << 62),
                          ),
                        ),
                        KvRow(
                          context.l.workerLoanOutstanding,
                          context.fmt.money(data.loan(id, paidOn)),
                        ),
                      ],
                    ),
                  ),
                  DateField(
                    label: v1Text(context, 'Payment date', 'ಪಾವತಿ ದಿನಾಂಕ'),
                    value: paidOn,
                    onChanged: (d) => setState(() => paidOn = dateOnly(d)),
                  ),
                  fieldGap,
                  MoneyField(
                    controller: cash,
                    label: v1Text(
                      context,
                      'Paid to worker (₹)',
                      'ಪಾವತಿ ಮೊತ್ತ (₹)',
                    ),
                    validator: (v) =>
                        v.trim().isNotEmpty && parseRupees(v) == null
                        ? l.invalidNumber
                        : null,
                  ),
                  fieldGap,
                  MoneyField(
                    controller: deduction,
                    label: v1Text(
                      context,
                      'Loan deduction (₹)',
                      'ಸಾಲದ ಕಡಿತ (₹)',
                    ),
                    validator: (v) =>
                        v.trim().isNotEmpty && parseRupees(v) == null
                        ? l.invalidNumber
                        : null,
                  ),
                  fieldGap,
                  Text(
                    v1Text(
                      context,
                      'Partial payment is allowed. The remainder stays due. Loan deductions require your entry.',
                      'ಭಾಗಶಃ ಪಾವತಿ ಮಾಡಬಹುದು. ಉಳಿದ ಮೊತ್ತ ಬಾಕಿ ಇರುತ್ತದೆ. ಸಾಲದ ಕಡಿತವನ್ನು ನೀವೇ ನಮೂದಿಸಬೇಕು.',
                    ),
                  ),
                  ChoiceChips(
                    values: PayMode.values,
                    selected: mode,
                    label: l.payMode,
                    onSelected: (m) => setState(() => mode = m),
                  ),
                  TextField(
                    controller: note,
                    decoration: InputDecoration(labelText: l.note),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(
                      v1Text(context, 'Record settlement', 'ಪಾವತಿ ದಾಖಲಿಸಿ'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LabourReports extends ConsumerStatefulWidget {
  const LabourReports({super.key, this.workerId, this.embedded = false});
  final bool embedded;
  final String? workerId;
  @override
  ConsumerState<LabourReports> createState() => _ReportsState();
}

class _ReportsState extends ConsumerState<LabourReports> {
  String period = 'week';
  String? worker;
  late DateTime anchor = dateOnly(ref.read(entryDayProvider));
  DateTimeRange? custom;
  @override
  void initState() {
    super.initState();
    worker = widget.workerId;
  }

  DateTimeRange get range {
    if (period == 'custom' && custom != null) return custom!;
    final start = switch (period) {
      'month' => DateTime(anchor.year, anchor.month),
      'year' => DateTime(anchor.year),
      _ => anchor.subtract(Duration(days: anchor.weekday - 1)),
    };
    final end = switch (period) {
      'month' => DateTime(anchor.year, anchor.month + 1, 0),
      'year' => DateTime(anchor.year, 12, 31),
      _ => start.add(const Duration(days: 6)),
    };
    return DateTimeRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final workers = ref.watch(workerSummariesProvider).value ?? [];
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(context.l.labourReports)),
      body: AsyncBody(
        value: ref.watch(payrollDataProvider),
        builder: (data) {
          final r = range;
          bool selected(String id) => worker == null || worker == id;
          bool inside(DateTime d) => !d.isBefore(r.start) && !d.isAfter(r.end);
          final txns =
              data.txns
                  .where((e) => selected(e.workerId) && inside(e.date))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          final loans =
              data.loans
                  .where((e) => selected(e.workerId) && inside(e.date))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          final settlements = data.settlements
              .where((e) => selected(e.workerId) && inside(e.date))
              .toList();
          final earned = txns
              .where((e) => e.kind == TxnKind.work)
              .fold<int>(0, (s, e) => s + e.amount);
          final paid = txns
              .where((e) => e.kind == TxnKind.payment)
              .fold<int>(0, (s, e) => s + e.amount);
          final deducted = settlements.fold<int>(
            0,
            (s, e) => s + e.loanDeduction,
          );
          final legacy = txns
              .where((e) => e.kind == TxnKind.advance)
              .fold<int>(0, (s, e) => s + e.amount);
          String name(String id) =>
              workers
                  .where((e) => e.worker.id == id)
                  .firstOrNull
                  ?.worker
                  .name ??
              id;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: worker ?? '',
                isExpanded: true,
                decoration: InputDecoration(labelText: l.tabWorkers),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.xAll)),
                  for (final w in workers)
                    DropdownMenuItem(
                      value: w.worker.id,
                      child: Text(w.worker.name),
                    ),
                ],
                onChanged: (v) => setState(() => worker = v == '' ? null : v),
              ),
              fieldGap,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in ['week', 'month', 'year', 'custom'])
                    ChoiceChip(
                      label: Text(switch (key) {
                        'week' => v1Text(context, 'Week', 'ವಾರ'),
                        'month' => v1Text(context, 'Month', 'ತಿಂಗಳು'),
                        'year' => v1Text(context, 'Year', 'ವರ್ಷ'),
                        _ => v1Text(context, 'Custom', 'ಆಯ್ದ ಅವಧಿ'),
                      }),
                      selected: period == key,
                      onSelected: (_) async {
                        if (key == 'custom') {
                          final result = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2015),
                            lastDate: DateTime.now(),
                            initialDateRange: custom,
                          );
                          if (result == null || !mounted) return;
                          setState(() {
                            custom = result;
                            period = key;
                          });
                        } else {
                          setState(() => period = key);
                        }
                      },
                    ),
                ],
              ),
              fieldGap,
              DateField(
                label: l.date,
                value: anchor,
                onChanged: (d) => setState(() => anchor = dateOnly(d)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${context.fmt.date(r.start)} – ${context.fmt.date(r.end)}',
                ),
              ),
              PaddedCard(
                child: Column(
                  children: [
                    KvRow(
                      v1Text(context, 'Wages earned', 'ಗಳಿಸಿದ ಕೂಲಿ'),
                      context.fmt.money(earned),
                    ),
                    KvRow(
                      v1Text(
                        context,
                        'Wages paid to workers',
                        'ಕಾರ್ಮಿಕರಿಗೆ ಪಾವತಿಸಿದ ಕೂಲಿ',
                      ),
                      context.fmt.money(paid - deducted),
                    ),
                    KvRow(
                      v1Text(context, 'Loan deductions', 'ಸಾಲದ ಕಡಿತಗಳು'),
                      context.fmt.money(deducted),
                    ),
                    if (legacy != 0)
                      KvRow(
                        v1Text(
                          context,
                          'Previous advance credits',
                          'ಹಿಂದಿನ ಮುಂಗಡ ಜಮಾ',
                        ),
                        context.fmt.money(legacy),
                      ),
                    KvRow(
                      v1Text(
                        context,
                        'Wages due at period end',
                        'ಅವಧಿ ಅಂತ್ಯದ ಕೂಲಿ ಬಾಕಿ',
                      ),
                      context.fmt.money(
                        workers
                            .where((e) => selected(e.worker.id))
                            .fold<int>(
                              0,
                              (s, w) =>
                                  s +
                                  data
                                      .due(w.worker.id, r.end)
                                      .clamp(0, 1 << 62),
                            ),
                      ),
                    ),
                    KvRow(
                      v1Text(
                        context,
                        'Loans given in period',
                        'ಈ ಅವಧಿಯಲ್ಲಿ ನೀಡಿದ ಸಾಲ',
                      ),
                      context.fmt.money(
                        loans
                            .where((e) => ['previous', 'new'].contains(e.kind))
                            .fold<int>(0, (s, e) => s + e.amount),
                      ),
                    ),
                    KvRow(
                      v1Text(
                        context,
                        'Loan repayments (cash)',
                        'ಸಾಲ ಮರುಪಾವತಿ (ನಗದು)',
                      ),
                      context.fmt.money(
                        loans
                            .where((e) => e.kind == 'repayment')
                            .fold<int>(0, (s, e) => s + e.amount),
                      ),
                    ),
                    KvRow(
                      v1Text(
                        context,
                        'Loan outstanding at period end',
                        'ಅವಧಿ ಅಂತ್ಯದ ಸಾಲದ ಬಾಕಿ',
                      ),
                      context.fmt.money(
                        workers
                            .where((e) => selected(e.worker.id))
                            .fold<int>(
                              0,
                              (s, w) => s + data.loan(w.worker.id, r.end),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                v1Text(
                  context,
                  'Earnings follow work dates; payments follow payment dates.',
                  'ಗಳಿಕೆಯನ್ನು ಕೆಲಸದ ದಿನಾಂಕದಂತೆ, ಪಾವತಿಯನ್ನು ಪಾವತಿ ದಿನಾಂಕದಂತೆ ತೋರಿಸಲಾಗಿದೆ.',
                ),
              ),
              SectionTitle(v1Text(context, 'By worker', 'ಕಾರ್ಮಿಕರ ಪ್ರಕಾರ')),
              for (final w in workers.where((e) => selected(e.worker.id)))
                PaddedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        w.worker.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      KvRow(
                        l.attendance(AttendanceStatus.present),
                        '${data.attendance.where((a) => a.workerId == w.worker.id && a.status == AttendanceStatus.present && inside(a.date)).length}',
                      ),
                      KvRow(
                        l.attendance(AttendanceStatus.half),
                        '${data.attendance.where((a) => a.workerId == w.worker.id && a.status == AttendanceStatus.half && inside(a.date)).length}',
                      ),
                      KvRow(
                        l.earned,
                        context.fmt.money(
                          txns
                              .where(
                                (e) =>
                                    e.workerId == w.worker.id &&
                                    e.kind == TxnKind.work,
                              )
                              .fold<int>(0, (s, e) => s + e.amount),
                        ),
                      ),
                      KvRow(
                        v1Text(context, 'Paid to worker', 'ಕಾರ್ಮಿಕರಿಗೆ ಪಾವತಿ'),
                        context.fmt.money(
                          txns
                                  .where(
                                    (e) =>
                                        e.workerId == w.worker.id &&
                                        e.kind == TxnKind.payment,
                                  )
                                  .fold<int>(0, (s, e) => s + e.amount) -
                              settlements
                                  .where((e) => e.workerId == w.worker.id)
                                  .fold<int>(0, (s, e) => s + e.loanDeduction),
                        ),
                      ),
                      KvRow(
                        l.due,
                        context.fmt.money(data.due(w.worker.id, r.end)),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettlementForm(worker: w.worker),
                          ),
                        ),
                        child: Text(context.l.settleWages),
                      ),
                    ],
                  ),
                ),
              SectionTitle(v1Text(context, 'Settlements', 'ಕೂಲಿ ಪಾವತಿಗಳು')),
              for (final s in settlements)
                PaddedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(name(s.workerId)),
                      Text(
                        '${context.fmt.date(s.periodStart)} – ${context.fmt.date(s.periodEnd)}',
                      ),
                      Text('${l.date}: ${context.fmt.date(s.date)}'),
                      KvRow(
                        v1Text(context, 'Paid to worker', 'ಕಾರ್ಮಿಕರಿಗೆ ಪಾವತಿ'),
                        context.fmt.money(s.cashPaid),
                      ),
                      KvRow(
                        v1Text(context, 'Loan deduction', 'ಸಾಲದ ಕಡಿತ'),
                        context.fmt.money(s.loanDeduction),
                      ),
                      if (s.note.isNotEmpty) Text(s.note),
                      TextButton.icon(
                        icon: const Icon(Icons.undo),
                        label: Text(
                          v1Text(
                            context,
                            'Cancel settlement',
                            'ಪಾವತಿ ರದ್ದುಮಾಡಿ',
                          ),
                        ),
                        onPressed: () async {
                          if (await confirm(
                                context,
                                title: v1Text(
                                  context,
                                  'Cancel this settlement?',
                                  'ಈ ಪಾವತಿ ರದ್ದುಮಾಡಬೇಕೇ?',
                                ),
                                body: v1Text(
                                  context,
                                  'Restores wages due and any loan deduction. You can then enter the corrected payment.',
                                  'ಕೂಲಿ ಬಾಕಿ ಮತ್ತು ಸಾಲದ ಕಡಿತವನ್ನು ಹಿಂದಿರುಗಿಸುತ್ತದೆ. ನಂತರ ಸರಿಯಾದ ಪಾವತಿಯನ್ನು ನಮೂದಿಸಬಹುದು.',
                                ),
                              ) &&
                              context.mounted) {
                            await perform(
                              context,
                              () =>
                                  PayrollRepository(ref.read(databaseProvider))
                                      .cancelSettlement(s.id),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              SectionTitle(l.ledger),
              if (txns.isEmpty && loans.isEmpty) Text(l.noLedger),
              for (final t in txns)
                ListTile(
                  isThreeLine: true,
                  title: Text(name(t.workerId)),
                  subtitle: Text(
                    '${context.fmt.date(t.date)} · ${t.kind == TxnKind.advance ? v1Text(context, 'Previous advance credit', 'ಹಿಂದಿನ ಮುಂಗಡ ಜಮಾ') : l.txnKind(t.kind)}\n${context.fmt.money(t.amount)}${t.note.isEmpty ? '' : ' · ${t.note}'}',
                  ),
                ),
              for (final e in loans)
                ListTile(
                  title: Text(
                    '${name(e.workerId)} · ${loanKind(context, e.kind)}',
                  ),
                  subtitle: Text(
                    '${context.fmt.date(e.date)} · ${context.fmt.money(e.amount)}${e.note.isEmpty ? '' : ' · ${e.note}'}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
