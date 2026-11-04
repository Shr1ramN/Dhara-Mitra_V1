import '../domain/wages.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import 'attendance_tab.dart';
import 'payroll_screens.dart';
import 'payment_sheet.dart';

enum LabourTab { workers, attendance, dues, reports }

class LabourScreen extends StatelessWidget {
  const LabourScreen({super.key, this.initialTab = LabourTab.workers});

  final LabourTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return DefaultTabController(
      key: ValueKey(initialTab),
      length: LabourTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.labourTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.tabWorkers),
              Tab(text: l.tabAttendance),
              Tab(text: l.tabDues),
              Tab(text: context.l.labourReports),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _WorkersTab(),
            AttendanceTab(),
            _DuesTab(),
            LabourReports(embedded: true),
          ],
        ),
      ),
    );
  }
}

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.appColors.accentSoft,
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: display(size * 0.42, color: context.appColors.accentDark),
    ),
  );
}

class DueText extends StatelessWidget {
  const DueText(this.balance, {super.key});

  final WorkerBalance balance;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final due = balance.due;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          due > 0
              ? formatRupees(due, showPaise: true)
              : due < 0
              ? l.advanceHeld(formatRupees(-due, showPaise: true))
              : l.settled,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: due > 0
                ? context.appColors.accentDark
                : context.appColors.okText,
          ),
        ),
        if (due > 0)
          Text(
            l.due,
            style: TextStyle(fontSize: 11, color: context.appColors.textMuted),
          ),
      ],
    );
  }
}

String rolesText(AppLocalizations l, List<WorkerRole> roles) =>
    roles.map(l.role).join(', ');

class _WorkersTab extends ConsumerWidget {
  const _WorkersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      body: AsyncBody(
        value: ref.watch(workerSummariesProvider),
        builder: (workers) => ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.push('/worker-form'),
                icon: Icon(Icons.person_add_alt),
                label: Text(l.addWorker),
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/labour?tab=reports'),
              icon: Icon(Icons.bar_chart),
              label: Text(l.labourReports),
            ),
            SizedBox(height: 12),
            if (workers.isEmpty)
              EmptyState(icon: Icons.groups_outlined, text: l.noWorkers),
            for (final s in workers)
              PaddedCard(
                onTap: () => context.push('/worker/${s.worker.id}'),
                child: Row(
                  children: [
                    WorkerAvatar(s.worker.name),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.worker.name,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              if (s.worker.roles.isNotEmpty ||
                                  s.worker.customRoles.isNotEmpty)
                                [
                                  rolesText(l, s.worker.roles),
                                  ...s.worker.customRoles,
                                ].where((v) => v.isNotEmpty).join(', '),
                              if (s.worker.dayRate > 0)
                                context.fmt.rate(
                                  s.worker.dayRate,
                                  RateUnit.day,
                                ),
                              if (!s.worker.active) l.inactive,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DueText(s.balance),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DuesTab extends ConsumerWidget {
  const _DuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return AsyncBody(
      value: ref.watch(workerSummariesProvider),
      builder: (workers) {
        final owed = workers.where((s) => s.balance.due > 0).toList()
          ..sort((a, b) => b.balance.due.compareTo(a.balance.due));
        final total = owed.fold(0, (sum, s) => sum + s.balance.due);
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.appColors.okBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.totalDue,
                          style: TextStyle(
                            color: context.appColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formatRupees(total, showPaise: true),
                          style: display(26, color: context.appColors.text),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: context.appColors.text,
                    size: 28,
                  ),
                ],
              ),
            ),
            if (owed.isEmpty)
              EmptyState(icon: Icons.check_circle_outline, text: l.nobodyDue),
            for (final s in owed)
              PaddedCard(
                onTap: () => context.push('/worker/${s.worker.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        WorkerAvatar(s.worker.name),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.worker.name,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                formatRupees(s.balance.due, showPaise: true),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.accentDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => showPaymentSheet(
                        context,
                        worker: s.worker,
                        kind: TxnKind.payment,
                        suggested: s.balance.due,
                      ),
                      child: Text(context.l.settleWages),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
