import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/v1.dart';
import '../../../core/widgets.dart';
import '../../calendar/calendar_records.dart';
import '../../calendar/date_note.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l, fmt = context.fmt, today = ref.watch(todayProvider);
    final workers = ref.watch(workerSummariesProvider).value ?? [];
    final due = workers.fold<int>(
      0,
      (s, w) => s + (w.balance.due > 0 ? w.balance.due : 0),
    );
    final present = (ref.watch(attendanceProvider(today)).value?.values ?? [])
        .where((e) => e.status != AttendanceStatus.absent)
        .length;
    final records = ref.watch(calendarRecordsProvider).value ?? [];
    final income = records
        .where((r) => r.category == 'note' && r.title == 'sale')
        .fold<int>(
          0,
          (sum, r) =>
              sum + ((noteValues(r.rawNotes)['incomePaise'] as int?) ?? 0),
        );
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final work = records
        .where(
          (r) =>
              (r.category == 'activity' || r.category == 'note') &&
              !calendarDay(r.date).isBefore(start) &&
              !calendarDay(r.date).isAfter(calendarDay(today)),
        )
        .length;
    final harvests = records
        .where((r) => calendarCategoryMatches(r, 'harvest'))
        .length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Text(
              fmt.weekdayDate(today),
              style: TextStyle(color: context.appColors.textMuted),
            ),
            SizedBox(height: 2),
            Text('${l.namaskara} 🙏', style: display(26)),
            OutlinedButton.icon(
              onPressed: () => context.push('/farms'),
              icon: Icon(Icons.swap_horiz),
              label: Text(l.fFarms),
            ),
            SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final large = MediaQuery.textScalerOf(context).scale(16) > 19.2;
                final width = large && constraints.maxWidth < 400
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _FarmSummaryTile(
                        label: l.tabAttendance,
                        value: '$present',
                        detail: v1Text(context, 'Present today', 'ಇಂದು ಹಾಜರು'),
                        icon: Icons.how_to_reg,
                        onTap: () => context.push('/labour?tab=attendance'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _FarmSummaryTile(
                        label: v1Text(context, 'Worker dues', 'ಕಾರ್ಮಿಕರ ಬಾಕಿ'),
                        value: fmt.money(due),
                        detail: v1Text(context, 'Pending wages', 'ಬಾಕಿ ವೇತನ'),
                        icon: Icons.groups_outlined,
                        green: true,
                        onTap: () => context.push('/labour?tab=dues'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _FarmSummaryTile(
                        label: v1Text(context, 'Recent work', 'ಇತ್ತೀಚಿನ ಕೆಲಸ'),
                        value: '$work',
                        detail: v1Text(context, 'This week', 'ಈ ವಾರ'),
                        icon: Icons.assignment_outlined,
                        onTap: () => context.go('/calendar'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _FarmSummaryTile(
                        label: v1Text(context, 'Harvests', 'ಕೊಯ್ಲುಗಳು'),
                        value: '$harvests',
                        detail: v1Text(
                          context,
                          'Saved records',
                          'ಉಳಿಸಿದ ದಾಖಲೆಗಳು',
                        ),
                        icon: Icons.eco_outlined,
                        green: true,
                        onTap: () => context.go('/calendar?category=harvest'),
                      ),
                    ),
                  ],
                );
              },
            ),
            SectionTitle(l.nFarmTools),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in <(String, IconData, String)>[
                  (l.farmActivity, Icons.grass, '/date-note'),
                  (
                    v1Text(context, 'Sold to Buyer', 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ'),
                    Icons.payments_outlined,
                    '/date-note?label=sale',
                  ),
                  (
                    l.navHarvest,
                    Icons.eco_outlined,
                    '/date-note?label=harvest',
                  ),
                  (l.xCalendar, Icons.calendar_month, '/calendar'),
                  (l.labourManagement, Icons.groups_outlined, '/labour'),
                ])
                  ActionChip(
                    avatar: Icon(item.$2, size: 18),
                    label: Text(item.$1),
                    onPressed: () => context.push(item.$3),
                  ),
              ],
            ),
            SectionTitle(l.money),
            KvRow(l.toPayWorkers, fmt.money(due)),
            KvRow(
              v1Text(context, 'Crop sale income', 'ಬೆಳೆ ಮಾರಾಟದ ಆದಾಯ'),
              fmt.money(income),
            ),
            TextButton(
              onPressed: () => context.push('/calendar?category=income'),
              child: Text(v1Text(context, 'View sales', 'ಮಾರಾಟಗಳನ್ನು ನೋಡಿ')),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/labour?tab=reports'),
              icon: Icon(Icons.bar_chart),
              label: Text(l.labourReports),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmSummaryTile extends StatelessWidget {
  const _FarmSummaryTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.green = false,
  });
  final String label, value, detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final color = green ? context.appColors.okText : context.appColors.accent;
    return Material(
      color: green ? context.appColors.okBg : context.appColors.accentSoft,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.text,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: display(24, color: context.appColors.text),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: context.appColors.okText,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
