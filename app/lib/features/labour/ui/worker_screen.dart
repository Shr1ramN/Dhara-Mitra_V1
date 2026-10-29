import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/indian_phone.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/labour_repository.dart';
import 'labour_screen.dart';
import 'payment_sheet.dart';
import 'worker_rates_screen.dart';

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
                icon: const Icon(Icons.price_change_outlined),
                tooltip: l.xRate,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerRatesScreen(workerId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: l.xShareStatement,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: [
                      l.appName,
                      w.name,
                      l.ledger,
                      for (final line in ledger.value ?? const <LedgerLine>[])
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
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              PaddedCard(
                child: Row(
                  children: [
                    WorkerAvatar(w.name, size: 48),
                    const SizedBox(width: 12),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            [
                              if (w.dayRate > 0)
                                fmt.rate(w.dayRate, RateUnit.day),
                              if (w.pieceRate != null && w.pieceUnit != null)
                                fmt.rate(w.pieceRate!, w.pieceUnit!),
                              if (w.phone.isNotEmpty) w.phone,
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
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
                        icon: const Icon(Icons.call_outlined),
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
              KpiRow(
                children: [
                  Kpi(label: l.earned, value: formatRupees(s.balance.earned)),
                  Kpi(
                    label: l.paidAdvance,
                    value: formatRupees(s.balance.given),
                  ),
                  Kpi(
                    label: s.balance.due < 0 ? l.advance : l.due,
                    value: formatRupees(s.balance.due.abs()),
                    highlight: s.balance.due > 0,
                  ),
                ],
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
                      child: Text(l.advance),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => showPaymentSheet(
                        context,
                        worker: w,
                        kind: TxnKind.payment,
                        suggested: s.balance.due > 0 ? s.balance.due : null,
                      ),
                      child: Text(l.pay),
                    ),
                  ),
                ],
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
                                      ? AppColors.text
                                      : AppColors.okText,
                                  background: line.txn.kind == TxnKind.work
                                      ? AppColors.background
                                      : AppColors.okBg,
                                ),
                                title: Text(
                                  line.txn.note.isNotEmpty
                                      ? line.txn.note
                                      : l.txnKind(line.txn.kind),
                                  style: const TextStyle(
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
                                    l.balanceAfter(formatRupees(line.dueAfter)),
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${line.txn.kind == TxnKind.work ? '+' : '−'} ${formatRupees(line.txn.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: line.txn.kind == TxnKind.work
                                        ? AppColors.text
                                        : AppColors.okText,
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
