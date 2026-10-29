import '../../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/labour_repository.dart';
import '../domain/wages.dart';
import 'payment_sheet.dart';

enum LabourTab { workers, attendance, dues }

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
            tabs: [
              Tab(text: l.tabWorkers),
              Tab(text: l.tabAttendance),
              Tab(text: l.tabDues),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_WorkersTab(), _AttendanceTab(), _DuesTab()],
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
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: display(size * 0.42, color: AppColors.accentDark),
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
              ? formatRupees(due)
              : due < 0
              ? l.advanceHeld(formatRupees(-due))
              : l.settled,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: due > 0 ? AppColors.accentDark : AppColors.okText,
          ),
        ),
        if (due > 0)
          Text(
            l.due,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-worker',
        onPressed: () => context.push('/worker-form'),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.addWorker),
      ),
      body: AsyncBody(
        value: ref.watch(workerSummariesProvider),
        builder: (workers) => workers.isEmpty
            ? EmptyState(icon: Icons.groups_outlined, text: l.noWorkers)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  for (final s in workers)
                    PaddedCard(
                      onTap: () => context.push('/worker/${s.worker.id}'),
                      child: Row(
                        children: [
                          WorkerAvatar(s.worker.name),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.worker.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
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

class _AttendanceTab extends ConsumerStatefulWidget {
  const _AttendanceTab();

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  late DateTime _day = ref.read(entryDayProvider);
  final _work = TextEditingController();
  final _individualWork = <String, TextEditingController>{};
  Map<String, AttendanceStatus>? _marks;
  DateTime? _loadedFor;

  @override
  void dispose() {
    _work.dispose();
    for (final controller in _individualWork.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setDay(DateTime day) => setState(() {
    _day = dateOnly(day);
    _marks = null;
  });

  Future<void> _save(List<WorkerSummary> workers) async {
    final marks = _marks ?? const {};

    await ref.read(labourRepositoryProvider).saveAttendance(_day, {
      for (final s in workers)
        s.worker.id: AttendanceMark(
          marks[s.worker.id] ?? AttendanceStatus.absent,
          work: _individualWork[s.worker.id]?.text.trim() ?? '',
        ),
    });
    if (mounted) showSnack(context, context.l.attendanceSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final workersAsync = ref.watch(workerSummariesProvider);
    final saved = ref.watch(attendanceProvider(_day));

    if (saved case AsyncData(value: final entries)
        when _marks == null || _loadedFor != _day) {
      _marks = {for (final e in entries.values) e.workerId: e.status};
      _loadedFor = _day;
      final firstWork = entries.values
          .map((e) => e.work)
          .where((w) => w.isNotEmpty)
          .firstOrNull;
      _work.text = firstWork ?? '';
      for (final c in _individualWork.values) {
        c.text = '';
      }
      for (final e in entries.values) {
        (_individualWork[e.workerId] ??= TextEditingController()).text = e.work;
      }
    }

    return AsyncBody(
      value: workersAsync,
      builder: (all) {
        final workers = all.where((s) => s.worker.active).toList();
        if (workers.isEmpty) {
          return EmptyState(icon: Icons.groups_outlined, text: l.noWorkers);
        }
        final marks = _marks ?? const <String, AttendanceStatus>{};
        var present = 0;
        var wages = 0;
        for (final s in workers) {
          final status = marks[s.worker.id] ?? AttendanceStatus.absent;
          if (status != AttendanceStatus.absent) present++;
          wages += attendanceWage(
            status,
            dayRate: s.worker.dayRate,
            halfDayRate: s.worker.halfDayRate,
          );
        }
        final isToday = isSameDay(_day, ref.read(todayProvider));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            PaddedCard(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _setDay(addDays(_day, -1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime(2015),
                          lastDate: ref.read(todayProvider),
                        );
                        if (picked != null) _setDay(picked);
                      },
                      child: Column(
                        children: [
                          Text(
                            isToday
                                ? '${l.today} · ${fmt.dayMonth(_day)}'
                                : fmt.weekdayDate(_day),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${l.presentCount(present)} · ${l.wages} ${formatRupees(wages)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isToday ? null : () => _setDay(addDays(_day, 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _work,
              decoration: InputDecoration(
                labelText: l.workToday,
                hintText: l.workHint,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.copy_all),
              label: Text(l.fApplyAll),
              onPressed: () => setState(() {
                for (final s in workers) {
                  (_individualWork[s.worker.id] ??= TextEditingController())
                          .text =
                      _work.text;
                }
              }),
            ),
            for (final s in workers)
              PaddedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        WorkerAvatar(s.worker.name, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.worker.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          s.worker.dayRate > 0
                              ? fmt.rate(s.worker.dayRate, RateUnit.day)
                              : l.noDayRate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _individualWork.putIfAbsent(
                        s.worker.id,
                        TextEditingController.new,
                      ),
                      decoration: InputDecoration(
                        labelText: l.workToday,
                        hintText: l.workHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AttendanceStatus>(
                      showSelectedIcon: false,
                      segments: [
                        for (final st in AttendanceStatus.values)
                          ButtonSegment(
                            value: st,
                            label: Text(l.attendance(st)),
                          ),
                      ],
                      selected: {marks[s.worker.id] ?? AttendanceStatus.absent},
                      onSelectionChanged: (v) => setState(
                        () => _marks = {...marks, s.worker.id: v.first},
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _save(workers),
              icon: const Icon(Icons.check),
              label: Text(l.saveAttendance),
            ),
          ],
        );
      },
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.text,
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupees(total),
                          style: display(26, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
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
                child: Row(
                  children: [
                    WorkerAvatar(s.worker.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.worker.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            formatRupees(s.balance.due),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 40),
                      ),
                      onPressed: () => showPaymentSheet(
                        context,
                        worker: s.worker,
                        kind: TxnKind.payment,
                        suggested: s.balance.due,
                      ),
                      child: Text(l.pay),
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
