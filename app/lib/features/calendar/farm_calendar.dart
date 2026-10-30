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
  final searchController = TextEditingController();
  final resultsKey = GlobalKey();
  final pageScroll = ScrollController();

  void submitSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      search = searchController.text.trim();
      older = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !pageScroll.hasClients) return;
      // The lazy list may not have built the results heading yet.
      if (resultsKey.currentContext == null) {
        await pageScroll.animateTo(
          pageScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      final target = resultsKey.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
          alignment: 0.1,
        );
      }
    });
  }

  String search = '', category = '';

  @override
  void dispose() {
    pageScroll.dispose();
    searchController.dispose();
    super.dispose();
  }

  bool allDates = false, older = false;
  bool explicitDay = false;
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
    'activity' => v1Text(context, 'Work', 'ಕೆಲಸ'),
    'expense' => context.l.xExpenses,
    'attendance' => context.l.tabAttendance,
    'payment' => v1Text(context, 'Payments', 'ಪಾವತಿಗಳು'),
    'harvest' => context.l.navHarvest,
    'sale' => context.l.xSales,
    'note' => context.l.notes,
    _ => context.l.xAll,
  };

  void selectDay(DateTime date) => setState(() {
    day = calendarDay(date);
    month = DateTime(date.year, date.month);
    allDates = false;
    explicitDay = true;
    range = null;
    older = false;
  });

  void resetFilters() => setState(() {
    searchController.clear();
    search = '';
    category = '';
    explicitDay = false;
    range = null;
    allDates = false;
    older = false;
  });

  void moveMonth(int delta) {
    final next = DateTime(month.year, month.month + delta);
    final last = DateTime(next.year, next.month + 1, 0).day;
    selectDay(DateTime(next.year, next.month, day.day > last ? last : day.day));
  }

  IconData categoryIcon(String value) => switch (value) {
    'activity' => Icons.eco_outlined,
    'expense' => Icons.receipt_long_outlined,
    'attendance' => Icons.groups_outlined,
    'payment' => Icons.account_balance_wallet_outlined,
    'harvest' => Icons.agriculture_outlined,
    'sale' => Icons.storefront_outlined,
    _ => Icons.sticky_note_2_outlined,
  };

  Future<void> chooseRange() async {
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      initialDateRange: range,
    );
    if (mounted && chosen != null) {
      setState(() {
        range = chosen;
        older = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = RecordQuery(search);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final today = calendarDay(ref.watch(todayProvider));
    final hasFilters =
        query.text.isNotEmpty ||
        category.isNotEmpty ||
        range != null ||
        allDates;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.xCalendar),
        actions: [
          TextButton.icon(
            onPressed: () => selectDay(today),
            icon: const Icon(Icons.today_outlined, size: 18),
            label: Text(v1Text(context, 'Today', 'ಇಂದು')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: Text(context.fmt.date(day)),
      ),
      body: AsyncBody(
        value: ref.watch(calendarRecordsProvider),
        builder: (records) {
          final matching =
              records
                  .where(
                    (r) =>
                        (category.isEmpty || category == r.category) &&
                        query.matches(r) &&
                        (range == null ||
                            calendarDateInRange(
                              r.date,
                              range!.start,
                              range!.end,
                            )),
                  )
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          final filtered = matching
              .where(
                (r) =>
                    allDates ||
                    (query.text.isNotEmpty && !explicitDay) ||
                    range != null ||
                    sameDay(day, r.date),
              )
              .toList();
          final visible = query.latest && !older
              ? filtered.take(1).toList()
              : filtered;
          final counts = <DateTime, int>{};
          for (final r in matching) {
            counts.update(calendarDay(r.date), (n) => n + 1, ifAbsent: () => 1);
          }
          final monthCount = matching
              .where(
                (r) => r.date.year == month.year && r.date.month == month.month,
              )
              .length;
          final days = DateTime(month.year, month.month + 1, 0).day;
          final offset = month.weekday - 1;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                controller: pageScroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF183D35), Color(0xFF326457)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.spa_outlined,
                          color: Color(0xFFE9B779),
                          size: 32,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          v1Text(
                            context,
                            'YOUR FARM, DAY BY DAY',
                            'ನಿಮ್ಮ ತೋಟ, ದಿನದಿಂದ ದಿನಕ್ಕೆ',
                          ),
                          style: text.labelSmall?.copyWith(
                            color: const Color(0xFFCDE3D5),
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          v1Text(
                            context,
                            'Every day tells a story.',
                            'ಪ್ರತಿ ದಿನಕ್ಕೂ ಒಂದು ಕಥೆ.',
                          ),
                          style: text.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          v1Text(
                            context,
                            'Find your work, harvests and little milestones.',
                            'ಕೆಲಸ, ಕೊಯ್ಲು ಮತ್ತು ಮುಖ್ಯ ಕ್ಷಣಗಳನ್ನು ಹುಡುಕಿ.',
                          ),
                          style: text.bodyMedium?.copyWith(
                            color: const Color(0xFFE0ECE5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => submitSearch(),
                    decoration: InputDecoration(
                      labelText: context.l.xSearch,
                      hintText: v1Text(
                        context,
                        'Try “last manure” or a buyer’s name',
                        '“ಕೊನೆಯ ಗೊಬ್ಬರ” ಅಥವಾ ಖರೀದಿದಾರರ ಹೆಸರು',
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: v1Text(
                                context,
                                'Clear search',
                                'ಹುಡುಕಾಟ ಅಳಿಸಿ',
                              ),
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                searchController.clear();
                                search = '';
                                older = false;
                              }),
                            ),
                          IconButton(
                            tooltip: context.l.xSearch,
                            onPressed: submitSearch,
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                    ),
                    onChanged: (v) => setState(() {
                      search = v;
                      older = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
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
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                c.isEmpty
                                    ? Icons.apps_rounded
                                    : categoryIcon(c),
                                size: 18,
                              ),
                              label: Text(label(c)),
                              selected: category == c,
                              onSelected: (_) => setState(() {
                                category = c;
                                older = false;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: v1Text(
                                  context,
                                  'Previous month',
                                  'ಹಿಂದಿನ ತಿಂಗಳು',
                                ),
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => moveMonth(-1),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${context.fmt.month(month.month)} ${month.year}',
                                      style: text.titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '$monthCount ${v1Text(context, 'records this month', 'ಈ ತಿಂಗಳ ದಾಖಲೆಗಳು')}',
                                      style: text.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: v1Text(
                                  context,
                                  'Next month',
                                  'ಮುಂದಿನ ತಿಂಗಳು',
                                ),
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => moveMonth(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              for (final d in v1Text(
                                context,
                                'M,T,W,T,F,S,S',
                                'ಸೋ,ಮಂ,ಬು,ಗು,ಶು,ಶ,ಭಾ',
                              ).split(','))
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: text.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ((offset + days + 6) ~/ 7) * 7,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisExtent: 52,
                                ),
                            itemBuilder: (context, i) {
                              if (i < offset || i >= offset + days) {
                                return const SizedBox();
                              }
                              final date = DateTime(
                                month.year,
                                month.month,
                                i - offset + 1,
                              );
                              final count = counts[date] ?? 0;
                              final selected = sameDay(date, day);
                              final isToday = sameDay(date, today);
                              return Semantics(
                                label:
                                    '${context.fmt.date(date)}, $count ${v1Text(context, 'records', 'ದಾಖಲೆಗಳು')}',
                                selected: selected,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: selected
                                          ? colors.onPrimary
                                          : colors.onSurface,
                                      backgroundColor: selected
                                          ? colors.primary
                                          : isToday
                                          ? colors.primaryContainer
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => selectDay(date),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontWeight: selected || isToday
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          width: count > 1 ? 12 : 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: count == 0
                                                ? Colors.transparent
                                                : selected
                                                ? colors.onPrimary
                                                : colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  v1Text(
                                    context,
                                    'Days with matching records',
                                    'ಹೊಂದುವ ದಾಖಲೆಗಳಿರುವ ದಿನಗಳು',
                                  ),
                                  style: text.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: Text(
                          v1Text(context, 'All dates', 'ಎಲ್ಲ ದಿನಾಂಕಗಳು'),
                        ),
                        selected:
                            allDates || (query.text.isNotEmpty && !explicitDay),
                        onSelected: (v) => setState(() {
                          allDates = v;
                          explicitDay = !v;
                          older = false;
                        }),
                      ),
                      InputChip(
                        avatar: const Icon(Icons.date_range_outlined, size: 18),
                        label: Text(
                          range == null
                              ? v1Text(context, 'Date range', 'ದಿನಾಂಕ ವ್ಯಾಪ್ತಿ')
                              : '${context.fmt.date(range!.start)} – ${context.fmt.date(range!.end)}',
                        ),
                        onPressed: chooseRange,
                        onDeleted: range == null
                            ? null
                            : () => setState(() {
                                range = null;
                                older = false;
                              }),
                      ),
                      if (hasFilters)
                        TextButton(
                          onPressed: resetFilters,
                          child: Text(
                            v1Text(
                              context,
                              'Reset filters',
                              'ಫಿಲ್ಟರ್ ಮರುಹೊಂದಿಸಿ',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    key: resultsKey,
                    children: [
                      Expanded(
                        child: Text(
                          (query.text.isNotEmpty && !explicitDay) ||
                                  allDates ||
                                  range != null
                              ? v1Text(
                                  context,
                                  'Matching records',
                                  'ಹೊಂದುವ ದಾಖಲೆಗಳು',
                                )
                              : context.fmt.date(day),
                          style: text.titleLarge,
                        ),
                      ),
                      Chip(label: Text('${filtered.length}')),
                    ],
                  ),
                  Text(
                    query.latest && !older
                        ? v1Text(context, 'Latest match', 'ಇತ್ತೀಚಿನ ಹೊಂದಾಣಿಕೆ')
                        : v1Text(
                            context,
                            'Newest first · tap a record to open',
                            'ಇತ್ತೀಚಿನವು ಮೊದಲು · ತೆರೆಯಲು ದಾಖಲೆಯನ್ನು ಒತ್ತಿ',
                          ),
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 36,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            v1Text(
                              context,
                              'No recorded entry.',
                              'ಯಾವುದೇ ದಾಖಲೆ ಇಲ್ಲ.',
                            ),
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            v1Text(
                              context,
                              'Try another day or adjust your filters.',
                              'ಬೇರೆ ದಿನವನ್ನು ಆರಿಸಿ ಅಥವಾ ಫಿಲ್ಟರ್ ಬದಲಿಸಿ.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  for (final r in visible)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            categoryIcon(r.category),
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        title: Text(r.title, style: text.titleMedium),
                        subtitle: Text(
                          '${context.fmt.date(r.date)} · ${label(r.category)}${r.notes.isEmpty ? '' : '\n${r.notes}'}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: () => open(r),
                      ),
                    ),
                  if (query.latest && !older && filtered.length > 1)
                    TextButton.icon(
                      onPressed: () => setState(() => older = true),
                      icon: const Icon(Icons.history),
                      label: Text(
                        v1Text(
                          context,
                          'Show older records',
                          'ಹಳೆಯ ದಾಖಲೆಗಳನ್ನು ತೋರಿಸಿ',
                        ),
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
