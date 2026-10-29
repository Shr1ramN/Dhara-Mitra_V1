import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/v1.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../diary/ui/diary_screen.dart';
import '../finance/finance_screens.dart';
import 'calendar_records.dart';
import 'calendar_editors.dart';

class FarmCalendarScreen extends ConsumerStatefulWidget {
  const FarmCalendarScreen({super.key});
  @override
  ConsumerState<FarmCalendarScreen> createState() => _FarmCalendarState();
}

class _FarmCalendarState extends ConsumerState<FarmCalendarScreen> {
  late DateTime day = ref.read(todayProvider);
  late DateTime month = DateTime(day.year, day.month);
  String search = '', category = '';
  bool allDates = false, older = false;
  DateTimeRange? range;
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> note([String? id]) async {
    final db = ref.read(databaseProvider);
    final old = id == null
        ? null
        : await (db.select(
            db.reminders,
          )..where((t) => t.id.equals(id))).getSingle();
    if (!mounted) return;
    await openEntryForm(
      context,
      title: v1Text(context, 'Date note', 'ದಿನದ ಟಿಪ್ಪಣಿ'),
      fields: [
        EntryField(
          'date',
          context.l.date,
          kind: InputKind.date,
          required: true,
          initial: old?.dueOn ?? day,
        ),
        EntryField(
          'title',
          context.l.xTitle,
          required: true,
          initial: old?.title,
        ),
        EntryField(
          'notes',
          context.l.notes,
          kind: InputKind.notes,
          initial: old?.notes,
        ),
      ],
      onSave: (v) => db
          .into(db.reminders)
          .insertOnConflictUpdate(
            RemindersCompanion.insert(
              id: id == null ? const Value.absent() : Value(id),
              title: v.text('title'),
              dueOn: v.date('date'),
              kind: const Value('dateNote'),
              done: const Value(true),
              notes: Value(v.text('notes')),
              updatedAt: Value(DateTime.now()),
            ),
          ),
    );
  }

  Future<void> open(CalendarRecord r) async {
    ref.read(entryDateProvider.notifier).select(r.date);
    try {
      if (r.category == 'note') {
        await note(r.id);
      } else if (r.category == 'payment') {
        await editCalendarPayment(context, ref, r.id);
      } else if (r.category == 'sale') {
        await editCalendarSale(context, ref, r.id);
      } else if (r.category == 'harvest' && r.route != '/collections') {
        await editCalendarHarvest(context, ref, r.id);
      } else if (r.category == 'activity') {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => DiaryDetail(r.id)),
        );
      } else if (r.category == 'expense') {
        final db = ref.read(databaseProvider);
        final expense = await (db.select(
          db.expenses,
        )..where((t) => t.id.equals(r.id))).getSingle();
        if (mounted) await const ExpensesScreen().edit(context, ref, expense);
      } else {
        await context.push(r.route);
      }
    } finally {
      if (mounted) ref.read(entryDateProvider.notifier).select(null);
    }
  }

  Future<void> add() async {
    final l = context.l;
    final route = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in <(String, String)>[
                (l.xActivity, '/fertilizer'),
                (l.tabAttendance, '/labour?tab=attendance'),
                (l.qaPay, '/labour?tab=dues'),
                (l.xExpenses, '/expenses'),
                (
                  '${l.navHarvest} · ${v1Text(context, 'Arecanut', 'ಅಡಿಕೆ')}',
                  '/harvest-form',
                ),
                (
                  '${l.navHarvest} · ${v1Text(context, 'Coconut', 'ತೆಂಗು')}',
                  '/produce',
                ),
                (l.fCollections, '/collections'),
                (l.xSales, '/sales'),
                (v1Text(context, 'Date note', 'ದಿನದ ಟಿಪ್ಪಣಿ'), 'note'),
              ])
                ListTile(
                  title: Text(item.$1),
                  trailing: const Icon(Icons.add),
                  onTap: () => Navigator.pop(context, item.$2),
                ),
            ],
          ),
        ),
      ),
    );
    if (route == null || !mounted) return;
    ref.read(entryDateProvider.notifier).select(day);
    try {
      if (route == 'note') {
        await note();
      } else if (route == '/expenses') {
        await const ExpensesScreen().edit(context, ref);
      } else {
        await context.push(route);
      }
    } finally {
      if (mounted) ref.read(entryDateProvider.notifier).select(null);
    }
  }

  String label(String key) => switch (key) {
    'activity' => context.l.xActivity,
    'expense' => context.l.xExpenses,
    'attendance' => context.l.tabAttendance,
    'payment' => context.l.xRecordPayment,
    'harvest' => context.l.navHarvest,
    'sale' => context.l.xSales,
    'note' => context.l.notes,
    _ => context.l.xAll,
  };

  @override
  Widget build(BuildContext context) {
    final query = RecordQuery(search);
    return Scaffold(
      appBar: AppBar(title: Text(context.l.xCalendar)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: Text(context.fmt.date(day)),
      ),
      body: AsyncBody(
        value: ref.watch(calendarRecordsProvider),
        builder: (records) {
          final matching = records
              .where(
                (r) =>
                    (category.isEmpty || category == r.category) &&
                    query.matches(r) &&
                    (range == null ||
                        (!r.date.isBefore(range!.start) &&
                            r.date.isBefore(
                              range!.end.add(const Duration(days: 1)),
                            ))),
              )
              .toList();
          final filtered = matching
              .where(
                (r) =>
                    allDates ||
                    search.isNotEmpty ||
                    range != null ||
                    sameDay(day, r.date),
              )
              .toList();
          final visible = query.latest && !older
              ? filtered.take(1).toList()
              : filtered;
          final days = DateTime(month.year, month.month + 1, 0).day;
          final offset = (month.weekday - 1) % 7;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: context.l.xSearch,
                  prefixIcon: const Icon(Icons.search),
                  helperText: v1Text(
                    context,
                    'Keywords: manure, spray, sales; “when did I last put manure”',
                    'ಪದಗಳು: ಗೊಬ್ಬರ, ಸಿಂಪಡಣೆ, ಮಾರಾಟ; “ಕೊನೆಯ ಗೊಬ್ಬರ”',
                  ),
                  helperMaxLines: 2,
                ),
                onChanged: (v) => setState(() {
                  search = v;
                  older = false;
                }),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final c in [
                    '',
                    'activity',
                    'attendance',
                    'expense',
                    'harvest',
                    'sale',
                    'payment',
                    'note',
                  ])
                    ChoiceChip(
                      label: Text(label(c)),
                      selected: category == c,
                      onSelected: (_) => setState(() => category = c),
                    ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month - 1),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${context.fmt.month(month.month)} ${month.year}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month + 1),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l.date,
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final chosen = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                        initialDateRange: range,
                      );
                      if (mounted && chosen != null) {
                        setState(() => range = chosen);
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  for (final d in v1Text(
                    context,
                    'M,T,W,T,F,S,S',
                    'ಸೋ,ಮಂ,ಬು,ಗು,ಶು,ಶ,ಭಾ',
                  ).split(','))
                    Expanded(child: Center(child: Text(d))),
                ],
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + days,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, i) {
                  if (i < offset) return const SizedBox();
                  final date = DateTime(
                    month.year,
                    month.month,
                    i - offset + 1,
                  );
                  final hit = matching.any((r) => sameDay(date, r.date));
                  return Semantics(
                    label: '${context.fmt.date(date)}${hit ? ' •' : ''}',
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: sameDay(date, day)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      onPressed: () => setState(() {
                        day = date;
                        allDates = false;
                      }),
                      child: Text(
                        '${date.day}${hit ? '\n•' : ''}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(v1Text(context, 'All dates', 'ಎಲ್ಲ ದಿನಾಂಕಗಳು')),
                value: allDates,
                onChanged: (v) => setState(() => allDates = v),
              ),
              if (range != null)
                ActionChip(
                  label: Text(
                    '${context.fmt.date(range!.start)} – ${context.fmt.date(range!.end)} ×',
                  ),
                  onPressed: () => setState(() => range = null),
                ),
              Text(
                search.isNotEmpty || allDates
                    ? v1Text(
                        context,
                        'Matching records · newest first',
                        'ಹೊಂದುವ ದಾಖಲೆಗಳು · ಇತ್ತೀಚಿನವು ಮೊದಲು',
                      )
                    : context.fmt.date(day),
              ),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    v1Text(context, 'No recorded entry.', 'ಯಾವುದೇ ದಾಖಲೆ ಇಲ್ಲ.'),
                  ),
                ),
              for (final r in visible)
                Card(
                  child: ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      '${context.fmt.date(r.date)} · ${label(r.category)}\n${r.notes}',
                    ),
                    isThreeLine: r.notes.isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(r),
                  ),
                ),
              if (query.latest && !older && filtered.length > 1)
                TextButton(
                  onPressed: () => setState(() => older = true),
                  child: Text(
                    v1Text(
                      context,
                      'Show older records',
                      'ಹಳೆಯ ದಾಖಲೆಗಳನ್ನು ತೋರಿಸಿ',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
