import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/v1.dart';
import '../../../core/widgets.dart';
import '../../common/forms.dart';
import '../data/labour_repository.dart';
import 'saved_tick.dart';

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key});
  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceState();
}

class _AttendanceState extends ConsumerState<AttendanceTab> {
  late DateTime day = dateOnly(ref.read(entryDayProvider));
  final work = TextEditingController();
  final rates = <String, TextEditingController>{};
  bool busy = false, loading = true;
  int loadId = 0;
  @override
  void initState() {
    super.initState();
    loadWork();
  }

  Future<void> loadWork() async {
    final token = ++loadId;
    final value = await ref
        .read(databaseProvider)
        .setting('attendance.work.${day.toIso8601String()}');
    if (mounted && token == loadId) {
      setState(() {
        work.text = value ?? '';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    work.dispose();
    for (final c in rates.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> changeDay(DateTime d) async {
    if (busy) return;
    await saveWork();
    if (!mounted) return;
    setState(() {
      day = dateOnly(d);
      loading = true;
      for (final c in rates.values) {
        c.dispose();
      }
      rates.clear();
    });
    await loadWork();
  }

  Future<void> saveWork() async {
    final db = ref.read(databaseProvider), date = day, text = work.text.trim();
    await db.putSetting('attendance.work.${date.toIso8601String()}', text);
  }

  Future<void> mark(WorkerSummary summary, AttendanceStatus status) async {
    if (busy || loading) return;
    final w = summary.worker;
    int? custom;
    if (w.wageType == 'other' && status != AttendanceStatus.absent) {
      final actual = parseRupees(rates[w.id]?.text ?? '');
      if (actual == null || actual <= 0) {
        showSnack(context, context.l.invalidNumber);
        return;
      }
      // Repository stores a full-day equivalent; the input is the actual pay.
      custom = status == AttendanceStatus.half ? actual * 2 : actual;
    } else if (w.wageType == 'daily') {
      custom = w.dayRate;
      if (status == AttendanceStatus.half && w.halfDayRate != null) {
        custom = w.halfDayRate! * 2;
      }
    }
    setState(() => busy = true);
    try {
      await saveWork();
      await ref.read(labourRepositoryProvider).saveAttendance(day, {
        w.id: AttendanceMark(status, work: work.text.trim(), rate: custom),
      });
      if (mounted) showSavedTick(context, context.l.attendanceSaved);
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final saved = ref.watch(attendanceProvider(day));
    return AsyncBody(
      value: ref.watch(workerSummariesProvider),
      builder: (all) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          PaddedCard(
            child: Row(
              children: [
                IconButton(
                  onPressed: busy ? null : () => changeDay(addDays(day, -1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: day.isAfter(dateOnly(DateTime.now()))
                                  ? dateOnly(DateTime.now())
                                  : day,
                              firstDate: DateTime(2015),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) await changeDay(d);
                          },
                    child: Text(
                      context.fmt.weekdayDate(day),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy || !day.isBefore(dateOnly(DateTime.now()))
                      ? null
                      : () => changeDay(addDays(day, 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          TextField(
            controller: work,
            enabled: !loading && !busy,
            decoration: InputDecoration(
              labelText: l.workToday,
              hintText: l.workHint,
            ),
            onChanged: (_) {
              // Persist each edit; no pending timer is lost when leaving the screen.
              unawaited(
                saveWork().catchError((Object e) {
                  if (context.mounted) {
                    showSnack(context, failureText(context, e));
                  }
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            v1Text(
              context,
              'Tap attendance to save automatically.',
              'ಹಾಜರಾತಿ ಆಯ್ಕೆ ಮಾಡಿದಾಗ ತಾನಾಗಿಯೇ ಉಳಿಯುತ್ತದೆ.',
            ),
          ),
          if (all.where((s) => s.worker.active).isEmpty)
            EmptyState(icon: Icons.groups_outlined, text: l.noWorkers),
          if (saved.isLoading) const LinearProgressIndicator(),
          if (saved.hasError) Text(l.xError),
          for (final summary in all.where(
            (s) => s.worker.active && saved.hasValue,
          ))
            Builder(
              builder: (context) {
                final w = summary.worker, e = saved.value?[w.id];
                final controller = rates.putIfAbsent(
                  w.id,
                  () => TextEditingController(
                    text: e != null && e.amount > 0
                        ? paiseToInput(e.amount)
                        : '',
                  ),
                );
                return PaddedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        w.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        w.wageType == 'daily'
                            ? context.fmt.rate(w.dayRate, RateUnit.day)
                            : v1Text(context, 'Other', 'ಇತರೆ'),
                      ),
                      if (w.wageType == 'other')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: MoneyField(
                            controller: controller,
                            label: v1Text(
                              context,
                              'Today’s wage (₹)',
                              'ಇಂದಿನ ಕೂಲಿ (₹)',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final st in AttendanceStatus.values)
                            ChoiceChip(
                              label: Text(l.attendance(st)),
                              selected: e?.status == st,
                              onSelected:
                                  busy ||
                                      loading ||
                                      !saved.hasValue ||
                                      day.isAfter(dateOnly(DateTime.now()))
                                  ? null
                                  : (_) => mark(summary, st),
                            ),
                        ],
                      ),
                      if (e != null)
                        Text('${l.wages}: ${context.fmt.money(e.amount)}'),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
