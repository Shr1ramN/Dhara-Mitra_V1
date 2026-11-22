import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/season.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../common/labels.dart';
import 'report_export.dart';
import 'report_repository.dart';

String reportCategory(BuildContext context, String category) =>
    {
      'sales': context.l.xSales,
      'labour': context.l.xLabourCost,
      'inputs': context.l.xInputCost,
      'expense': context.l.xExpenses,
      'interest': context.l.xInterestPaid,
      'premium': context.l.xPremiums,
      'claim': context.l.xClaims,
      'subsidy': context.l.xSubsidy,
      'dividend': context.l.xDividend,
    }[category] ??
    category;

final reportRepositoryProvider = Provider(
  (ref) => ReportRepository(ref.watch(databaseProvider)),
);
final reportProvider =
    StreamProvider.family<
      FarmReport,
      ({int year, int month, String? crop, String? plot})
    >(
      (ref, key) => ref
          .watch(reportRepositoryProvider)
          .watch(
            season: Season(key.year),
            today: ref.watch(todayProvider),
            startMonth: key.month,
            crop: key.crop,
            plot: key.plot,
          ),
    );

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _year;
  String? _crop, _plot;
  bool _exporting = false;
  Future<void> _export(FarmReport report, bool pdf) async {
    setState(() => _exporting = true);
    final l = context.l;
    final locale = Localizations.localeOf(context).languageCode;
    final rows = <List<Object?>>[
      [
        l.xSeason,
        '${_year ?? Season.of(ref.read(todayProvider), startMonth: ref.read(farmProvider).value?.seasonStartMonth ?? 6).startYear}',
      ],
      [l.xIncome, report.income / 100],
      [l.xCosts, report.costs / 100],
      [l.xProfit, report.profit / 100],
      for (final e in report.categories.entries)
        [reportCategory(context, e.key), e.value / 100],
      [l.date, l.xType, l.xTitle, '₹'],
      for (final line in report.lines.where(
        (l) => l.allocated(crop: _crop, plot: _plot) != 0,
      ))
        [
          context.fmt.date(line.date),
          reportCategory(context, line.category),
          line.label,
          (line.income ? 1 : -1) *
              line.allocated(crop: _crop, plot: _plot) /
              100,
        ],
    ];
    await perform(context, () async {
      final file = pdf
          ? await ReportExport.pdf(
              l.xReports,
              rows,
              kannada: locale == 'kn',
              footer: l.xReportBasis,
            )
          : await ReportExport.excel(l.xReports, rows);
      await ReportExport.share(file, l.xReports);
    });
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final month = ref.watch(farmProvider).value?.seasonStartMonth ?? 6;
    final current = Season.of(
      ref.watch(todayProvider),
      startMonth: month,
    ).startYear;
    final year = _year ?? current;
    final report = ref.watch(
      reportProvider((year: year, month: month, crop: _crop, plot: _plot)),
    );
    final previous = ref.watch(
      reportProvider((year: year - 1, month: month, crop: _crop, plot: _plot)),
    );
    final plots = ref.watch(plotsProvider).value ?? [];
    final names = ref.watch(workerNamesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.xReports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: year,
            decoration: InputDecoration(labelText: l.xSeason),
            items: [
              for (var y = current; y >= current - 15; y--)
                DropdownMenuItem(value: y, child: Text(Season(y).label)),
            ],
            onChanged: (y) => setState(() => _year = y),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _crop,
            decoration: InputDecoration(labelText: l.xCrop),
            items: [
              DropdownMenuItem(value: null, child: Text(l.xAll)),
              for (final e in cropOptions(context).entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _crop = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _plot,
            decoration: InputDecoration(labelText: l.xPlot),
            items: [
              DropdownMenuItem(value: null, child: Text(l.xAll)),
              for (final p in plots)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => _plot = v),
          ),
          const SizedBox(height: 16),
          Text(l.xReportBasis, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          AsyncBody(
            value: report,
            builder: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaddedCard(
                  child: Column(
                    children: [
                      KvRow(l.xIncome, context.fmt.money(r.income)),
                      KvRow(l.xCosts, context.fmt.money(r.costs)),
                      const Divider(),
                      KvRow(l.xProfit, context.fmt.money(r.profit)),
                      if (r.acres > 0)
                        KvRow(
                          l.xPerAcre,
                          context.fmt.money((r.profit / r.acres).round()),
                        ),
                    ],
                  ),
                ),
                for (final e in r.categories.entries)
                  KvRow(
                    reportCategory(context, e.key),
                    context.fmt.money(e.value),
                  ),
                SectionTitle(l.xYield),
                for (final e in r.yieldByUnit.entries)
                  KvRow(
                    '${recordLabel(context, e.key.split('|').first)} (${recordLabel(context, e.key.split('|').last)})',
                    formatQty(e.value),
                  ),
                if (_crop == 'areca' && (r.yieldByUnit['areca|kg'] ?? 0) > 0)
                  KvRow(
                    l.costPerKg,
                    context.fmt.money(
                      (r.costs / r.yieldByUnit['areca|kg']!).round(),
                    ),
                  ),
                SectionTitle(l.xLabourCost),
                for (final e in r.labourByWorker.entries)
                  KvRow(names[e.key] ?? l.xWorker, context.fmt.money(e.value)),
                SectionTitle(
                  '${l.xPreviousSeason} · ${Season(year - 1).label}',
                ),
                if (previous.value != null) ...[
                  KvRow(l.xIncome, context.fmt.money(previous.value!.income)),
                  KvRow(l.xCosts, context.fmt.money(previous.value!.costs)),
                  KvRow(l.xProfit, context.fmt.money(previous.value!.profit)),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(r, true),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l.xExportPdf),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(r, false),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l.xExportExcel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
