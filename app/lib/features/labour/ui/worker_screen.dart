import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/indian_phone.dart';

import '../../../core/enums.dart';
import '../../../core/db/database.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/labour_repository.dart';
import 'labour_screen.dart';
import 'payment_sheet.dart';
import 'payroll_screens.dart';
import '../../../core/v1.dart';

/// One worker's account: earned, given and every entry with the running balance (F3.4).
class WorkerScreen extends ConsumerWidget {
  const WorkerScreen({super.key, required this.workerId});

  final String workerId;

  Future<void> _onLongPress(
    BuildContext context,
    WidgetRef ref,
    LedgerLine line,
  ) async {
    final l = context.l;
    if (line.txn.refType != null) {
      showSnack(context, l.workEntryLocked);
      return;
    }
    if (await confirm(context, title: l.deleteEntry)) {
      await ref.read(labourRepositoryProvider).deleteTxn(line.txn.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final summary = ref.watch(workerSummaryProvider(workerId));
    final ledger = ref.watch(ledgerProvider(workerId));
    final payroll = ref.watch(payrollDataProvider).value;
    final settlements = {
      for (final entry in payroll?.settlements ?? <WorkerSettlement>[])
        entry.id: entry,
    };

    return AsyncBody(
      value: summary,
      builder: (s) {
        if (s == null) return Scaffold(appBar: AppBar());
        final w = s.worker;
        return Scaffold(
          appBar: AppBar(
            title: Text(w.name),
            actions: [
              IconButton(
                icon: Icon(Icons.ios_share),
                tooltip: l.xShareStatement,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: [
                      l.appName,
                      w.name,
                      l.ledger,
                      for (final line in ledger.value ?? <LedgerLine>[])
                        '${fmt.date(line.txn.date)} · ${l.txnKind(line.txn.kind)} · ${line.txn.note} · ${fmt.money(line.txn.amount)} · ${l.due}: ${fmt.money(line.dueAfter)}',
                      '${l.due}: ${fmt.money(s.balance.due)}',
                    ].join('\n'),
                    subject: w.name,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.editWorker,
                onPressed: () => context.push('/worker-form?id=${w.id}'),
                icon: Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              PaddedCard(
                child: Row(
                  children: [
                    WorkerAvatar(w.name, size: 48),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (w.roles.isNotEmpty || w.customRoles.isNotEmpty)
                            Text(
                              [
                                rolesText(l, w.roles),
                                ...w.customRoles,
                              ].where((r) => r.isNotEmpty).join(', '),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          Text(
                            [
                              if (w.dayRate > 0)
                                fmt.rate(w.dayRate, RateUnit.day),

                              if (w.phone.isNotEmpty) w.phone,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  for (final contact in [(w.phone, false), (w.telephone, true)])
                    if (contact.$1.isNotEmpty)
                      OutlinedButton.icon(
                        icon: Icon(Icons.call_outlined),
                        label: Text('${l.fCall} · ${contact.$1}'),
                        onPressed: () async {
                          final number = indianPhone(
                            contact.$1,
                            landline: contact.$2,
                          );
                          try {
                            if (number == null ||
                                !await launchUrl(
                                  Uri(scheme: 'tel', path: number),
                                )) {
                              throw StateError('dial');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showSnack(context, l.fCallUnavailable);
                            }
                          }
                        },
                      ),
                ],
              ),
              PaddedCard(
                child: Column(
                  children: [
                    KvRow(l.earned, fmt.money(s.balance.earned)),
                    KvRow(
                      v1Text(context, 'Wages settled', 'ಪಾವತಿಸಿದ ಕೂಲಿ'),
                      fmt.money(s.balance.given),
                    ),
                    KvRow(
                      s.balance.due < 0 ? l.advance : l.due,
                      fmt.money(s.balance.due.abs()),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showPaymentSheet(
                        context,
                        worker: w,
                        kind: TxnKind.advance,
                      ),
                      child: Text(context.l.workerLoan),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => showPaymentSheet(
                        context,
                        worker: w,
                        kind: TxnKind.payment,
                        suggested: s.balance.due > 0 ? s.balance.due : null,
                      ),
                      child: Text(context.l.settleWages),
                    ),
                  ),
                ],
              ),
              AsyncBody(
                value: ref.watch(payrollDataProvider),
                builder: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KvRow(
                      context.l.workerLoanOutstanding,
                      fmt.money(data.loan(w.id, DateTime.now())),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkerLoanForm(worker: w, repayment: true),
                        ),
                      ),
                      child: Text(
                        v1Text(
                          context,
                          'Record loan repayment',
                          'ಸಾಲ ಮರುಪಾವತಿ ದಾಖಲಿಸಿ',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.bar_chart),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LabourReports(workerId: w.id),
                        ),
                      ),
                      label: Text(context.l.labourReports),
                    ),
                    if (data.loans.any((entry) => entry.workerId == w.id)) ...[
                      SectionTitle(context.l.workerLoan),
                      for (final entry
                          in data.loans
                              .where((entry) => entry.workerId == w.id)
                              .toList()
                            ..sort((a, b) => b.date.compareTo(a.date)))
                        ListTile(
                          title: Text(loanKind(context, entry.kind)),
                          subtitle: Text(
                            '${fmt.date(entry.date)} · ${fmt.money(entry.amount)}${entry.note.isEmpty ? '' : ' · ${entry.note}'}',
                          ),
                        ),
                    ],
                    if (s.balance.advanced != 0)
                      Text(
                        v1Text(
                          context,
                          'Previous advances remain wage credits; they are not new loans.',
                          'ಹಿಂದಿನ ಮುಂಗಡಗಳು ಕೂಲಿ ಜಮಾ ಆಗಿಯೇ ಉಳಿಯುತ್ತವೆ; ಅವು ಹೊಸ ಸಾಲಗಳಲ್ಲ.',
                        ),
                      ),
                  ],
                ),
              ),
              SectionTitle(l.ledger),
              AsyncBody(
                value: ledger,
                builder: (lines) => lines.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        text: l.noLedger,
                      )
                    : Card(
                        child: Column(
                          children: [
                            for (final line in lines.reversed)
                              ListTile(
                                onLongPress: () =>
                                    _onLongPress(context, ref, line),
                                leading: RoundIcon(
                                  line.txn.kind == TxnKind.work
                                      ? Icons.handyman_outlined
                                      : Icons.payments_outlined,
                                  color: line.txn.kind == TxnKind.work
                                      ? context.appColors.text
                                      : context.appColors.okText,
                                  background: line.txn.kind == TxnKind.work
                                      ? context.appColors.background
                                      : context.appColors.okBg,
                                ),
                                title: Text(
                                  line.txn.note.isNotEmpty
                                      ? line.txn.note
                                      : l.txnKind(line.txn.kind),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    fmt.date(line.txn.date),
                                    if (line.txn.kind != TxnKind.work)
                                      l.txnKind(line.txn.kind),
                                    if (line.txn.mode != null &&
                                        line.txn.kind != TxnKind.work)
                                      l.payMode(line.txn.mode!),
                                    if (settlements[line.txn.refId]
                                            ?.loanDeduction
                                        case final int amount when amount > 0)
                                      '${v1Text(context, 'Loan deduction', 'ಸಾಲದ ಕಡಿತ')}: ${fmt.money(amount)}',
                                    l.balanceAfter(
                                      formatRupees(
                                        line.dueAfter,
                                        showPaise: true,
                                      ),
                                    ),
                                  ].join(' · '),
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${line.txn.kind == TxnKind.work ? '+' : '−'} ${formatRupees(settlements[line.txn.refId]?.cashPaid ?? line.txn.amount, showPaise: true)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: line.txn.kind == TxnKind.work
                                        ? context.appColors.text
                                        : context.appColors.okText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
