import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../common/labels.dart';
import '../common/feature_providers.dart';
import '../lots/domain/lot_view.dart';
import '../produce/produce_repository.dart';
import 'prices_repository.dart';

Map<String, String> priceGrades(BuildContext context) => {
  for (final g in ArecaGrade.values) g.name: context.l.grade(g),
  'oldChali': Localizations.localeOf(context).languageCode == 'kn'
      ? 'ಹಳೆಯ ಚಾಲಿ'
      : 'Old chali',
  'newChali': Localizations.localeOf(context).languageCode == 'kn'
      ? 'ಹೊಸ ಚಾಲಿ'
      : 'New chali',
  'doubleChali': Localizations.localeOf(context).languageCode == 'kn'
      ? 'ಡಬಲ್ ಚಾಲಿ'
      : 'Double chali',
  'pepper': context.l.cropPepper,
  'nut': context.l.xNuts,
  'copra': context.l.xCopra,
  'banana': context.l.cropBanana,
  'nendran': Localizations.localeOf(context).languageCode == 'kn'
      ? 'ನೇಂದ್ರ'
      : 'Nendran',
  'elakki': Localizations.localeOf(context).languageCode == 'kn'
      ? 'ಏಲಕ್ಕಿ'
      : 'Elakki',
};
final pricesRepositoryProvider = Provider(
  (ref) => PricesRepository(ref.watch(databaseProvider)),
);
final pricesProvider = StreamProvider(
  (ref) => ref.watch(pricesRepositoryProvider).watch(),
);
final priceAlertsProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.priceAlerts,
  )..where((a) => a.deleted.equals(false))).watch();
});

class PricesScreen extends ConsumerWidget {
  const PricesScreen({super.key});
  Future<void> _price(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xPrices,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(todayProvider),
        ),
        EntryField('source', l.xSource, required: true, initial: 'CAMPCO'),
        EntryField('market', l.xMarket, required: true),
        EntryField(
          'crop',
          l.xCrop,
          kind: InputKind.choice,
          required: true,
          initial: 'areca',
          options: cropOptions(context),
        ),
        EntryField(
          'grade',
          l.xGrade,
          kind: InputKind.choice,
          required: true,
          initial: 'chali',
          options: priceGrades(context),
        ),
        EntryField(
          'unit',
          l.xUnit,
          kind: InputKind.choice,
          required: true,
          initial: 'kg',
          options: {
            'kg': l.kgUnit,
            'quintal': Localizations.localeOf(context).languageCode == 'kn'
                ? 'ಕ್ವಿಂಟಾಲ್'
                : 'Quintal',
            'nut': l.xNuts,
            'bunch': l.xBunches,
          },
        ),
        EntryField(
          'modal',
          l.xModalPrice,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
        EntryField('minimum', l.xMinPrice, kind: InputKind.money),
        EntryField('maximum', l.xMaxPrice, kind: InputKind.money),
      ],
      onSave: (v) => ref
          .read(pricesRepositoryProvider)
          .save(
            date: v.date('date'),
            source: v.text('source'),
            market: v.text('market'),
            crop: v.text('crop'),
            grade: v.text('grade'),
            unit: v.text('unit'),
            modal: v.money('modal'),
            minimum: v.text('minimum').isEmpty ? null : v.money('minimum'),
            maximum: v.text('maximum').isEmpty ? null : v.money('maximum'),
          ),
    );
  }

  Future<void> _alert(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xPriceAlert,
      fields: [
        EntryField(
          'crop',
          l.xCrop,
          kind: InputKind.choice,
          required: true,
          initial: 'areca',
          options: cropOptions(context),
        ),
        EntryField(
          'grade',
          l.xGrade,
          kind: InputKind.choice,
          required: true,
          initial: 'chali',
          options: priceGrades(context),
        ),
        EntryField('market', l.xMarket),
        EntryField(
          'unit',
          l.xUnit,
          kind: InputKind.choice,
          required: true,
          initial: 'kg',
          options: {'kg': l.kgUnit, 'nut': l.xNuts, 'bunch': l.xBunches},
        ),
        EntryField(
          'direction',
          l.xType,
          kind: InputKind.choice,
          required: true,
          initial: 'above',
          options: {'above': l.xAbove, 'below': l.xBelow},
        ),
        EntryField(
          'target',
          l.xTarget,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
      ],
      onSave: (v) => ref
          .read(pricesRepositoryProvider)
          .alert(
            crop: v.text('crop'),
            grade: v.text('grade'),
            market: v.text('market'),
            unit: v.text('unit'),
            direction: v.text('direction'),
            target: v.money('target'),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final value = ref.watch(pricesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.xPrices),
          bottom: TabBar(
            tabs: [
              Tab(text: l.xPrices),
              Tab(text: l.xPriceAlert),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _price(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l.add),
              ),
              body: AsyncBody(
                value: value,
                builder: (all) {
                  final latest = <String, PriceSnapshot>{};
                  for (final p in all) {
                    latest.putIfAbsent(
                      '${p.crop}|${p.grade}|${p.market}|${p.source}|${p.unit}',
                      () => p,
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      Text(l.xNoLiveFeed),
                      const SizedBox(height: 12),
                      if (latest.isEmpty)
                        EmptyState(icon: Icons.show_chart, text: l.xEmpty),
                      for (final p in latest.values)
                        Card(
                          child: ListTile(
                            title: Text(
                              '${priceGrades(context)[p.grade] ?? p.grade} · ${context.fmt.money(p.modal)} / ${recordLabel(context, p.unit)}',
                            ),
                            subtitle: Text(
                              '${p.market} · ${p.source}\n${l.xLastUpdated}: ${context.fmt.date(p.date)}',
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _PriceHistory(p),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _alert(context, ref),
                icon: const Icon(Icons.add_alert_outlined),
                label: Text(l.add),
              ),
              body: AsyncBody(
                value: ref.watch(priceAlertsProvider),
                builder: (all) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    for (final a in all)
                      SwitchListTile(
                        title: Text(
                          '${priceGrades(context)[a.grade] ?? a.grade} · ${context.fmt.money(a.target)} / ${recordLabel(context, a.unit)}',
                        ),
                        subtitle: Text(
                          '${a.direction == 'above' ? l.xAbove : l.xBelow} · ${a.market.isEmpty ? l.xAll : a.market}',
                        ),
                        value: a.active,
                        onChanged: (active) => perform(context, () async {
                          final db = ref.read(databaseProvider);
                          await (db.update(
                            db.priceAlerts,
                          )..where((p) => p.id.equals(a.id))).write(
                            PriceAlertsCompanion(
                              active: Value(active),
                              updatedAt: Value(DateTime.now()),
                            ),
                          );
                        }),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l.delete,
                          onPressed: () => perform(context, () async {
                            final db = ref.read(databaseProvider);
                            await (db.update(
                              db.priceAlerts,
                            )..where((p) => p.id.equals(a.id))).write(
                              PriceAlertsCompanion(
                                deleted: const Value(true),
                                updatedAt: Value(DateTime.now()),
                              ),
                            );
                          }),
                        ),
                      ),
                    if (all.isEmpty)
                      EmptyState(
                        icon: Icons.notifications_none,
                        text: l.xEmpty,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceHistory extends ConsumerStatefulWidget {
  const _PriceHistory(this.price);
  final PriceSnapshot price;
  @override
  ConsumerState<_PriceHistory> createState() => _PriceHistoryState();
}

class _PriceHistoryState extends ConsumerState<_PriceHistory> {
  int _days = 30;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final p = widget.price;
    final history =
        (ref.watch(pricesProvider).value ?? <PriceSnapshot>[])
            .where(
              (v) =>
                  v.crop == p.crop &&
                  v.grade == p.grade &&
                  v.market == p.market &&
                  v.source == p.source &&
                  v.unit == p.unit &&
                  !v.date.isBefore(
                    ref.watch(todayProvider).subtract(Duration(days: _days)),
                  ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    var stock = 0.0;
    if (p.crop == 'areca') {
      final grade = ['oldChali', 'newChali', 'doubleChali'].contains(p.grade)
          ? 'chali'
          : p.grade;
      for (final v in ref.watch(lotViewsProvider).value ?? const <LotView>[]) {
        for (final e in v.remaining.entries) {
          if (e.key.name == grade) stock += e.value;
        }
      }
    } else {
      for (final v
          in ref.watch(produceProvider).value ?? const <ProduceView>[]) {
        if (v.lot.crop == p.crop && v.lot.unit == p.unit) stock += v.remaining;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.xHistory)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${p.market} · ${p.source} · ${priceGrades(context)[p.grade]}'),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 7, label: Text(l.xDays7)),
              ButtonSegment(value: 30, label: Text(l.xDays30)),
              ButtonSegment(value: 365, label: Text(l.xYear)),
            ],
            selected: {_days},
            onSelectionChanged: (v) => setState(() => _days = v.first),
          ),
          const SizedBox(height: 16),
          if (history.length > 1)
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _Trend(history, Theme.of(context).colorScheme.primary),
              ),
            ),
          if (stock > 0)
            KvRow(
              '${l.xStorage} · ${l.xValue}',
              context.fmt.money((stock * p.modal).round()),
            ),
          for (final price in history.reversed)
            ListTile(
              title: Text(context.fmt.date(price.date)),
              trailing: Text(
                '${context.fmt.money(price.modal)} / ${recordLabel(context, price.unit)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _Trend extends CustomPainter {
  _Trend(this.points, this.color);
  final List<PriceSnapshot> points;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final low = points.map((p) => p.modal).reduce(math.min);
    final high = points.map((p) => p.modal).reduce(math.max);
    final span = math.max(1, high - low);
    final duration = math.max(
      1,
      points.last.date.difference(points.first.date).inMilliseconds,
    );
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x =
          8 +
          (size.width - 16) *
              points[i].date.difference(points.first.date).inMilliseconds /
              duration;
      final y = 12 + (size.height - 24) * (1 - (points[i].modal - low) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _Trend oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
