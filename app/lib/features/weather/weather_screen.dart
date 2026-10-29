import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/db/database.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import 'weather_repository.dart';

final weatherRepositoryProvider = Provider(
  (ref) => WeatherRepository(ref.watch(databaseProvider)),
);
final weatherProvider = StreamProvider(
  (ref) => ref.watch(weatherRepositoryProvider).watch(),
);
final rainProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.rainEntries)
        ..where((r) => r.deleted.equals(false))
        ..orderBy([(r) => OrderingTerm.desc(r.date)]))
      .watch();
});

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _busy = false;
  bool _offline = false;
  Future<void> _refresh() async {
    final farm = ref.read(farmProvider).value;
    if (farm?.lat == null || farm?.lng == null) {
      await context.push('/farm');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(weatherRepositoryProvider).refresh(farm!.lat!, farm.lng!);
      if (mounted) setState(() => _offline = false);
    } catch (_) {
      if (mounted) setState(() => _offline = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rain([RainEntry? entry]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xRainLog,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: entry?.date ?? ref.read(todayProvider),
        ),
        EntryField(
          'mm',
          l.xMillimetres,
          kind: InputKind.quantity,
          required: true,
          maximum: 3000,
          initial: entry?.millimetres,
        ),
        EntryField(
          'notes',
          l.notes,
          kind: InputKind.notes,
          initial: entry?.notes,
        ),
      ],
      onSave: (v) => ref
          .read(weatherRepositoryProvider)
          .rain(v.date('date'), v.number('mm'), notes: v.text('notes')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final farm = ref.watch(farmProvider).value;
    final cache = ref.watch(weatherProvider).value;
    final matches =
        cache != null &&
        cache.latitude == farm?.lat &&
        cache.longitude == farm?.lng;
    final forecast = matches ? Forecast.parse(cache.payload) : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.xWeather),
        actions: [
          IconButton(
            tooltip: l.xRefresh,
            onPressed: _busy ? null : _refresh,
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _rain,
        icon: const Icon(Icons.water_drop_outlined),
        label: Text(l.xRainLog),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_offline) Text(l.xOffline),
          if (forecast == null) ...[
            Text(l.xNoWeather),
            OutlinedButton(
              onPressed: () => context.push('/farm'),
              child: Text(l.xLocation),
            ),
          ] else ...[
            Text(
              '${l.xLastUpdated}: ${context.fmt.date(cache!.fetchedOn)} ${DateFormat('HH:mm').format(cache.fetchedOn)}',
            ),
            Text(
              l.xWeatherSource,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SectionTitle(l.xForecast),
            for (final day in forecast.days)
              Card(
                child: ListTile(
                  title: Text(context.fmt.weekdayDate(day.date)),
                  subtitle: Text(
                    '${day.minimum.toStringAsFixed(0)}–${day.maximum.toStringAsFixed(0)} °C · ${day.rain} mm',
                  ),
                  trailing: Text('${day.chance}% ☔'),
                ),
              ),
            ExpansionTile(
              title: Text(l.xRainChance),
              children: [
                for (final hour
                    in forecast.hours
                        .where((h) => h.date.isAfter(DateTime.now()))
                        .take(24))
                  ListTile(
                    title: Text(
                      '${context.fmt.dayMonth(hour.date)} ${DateFormat('HH:mm').format(hour.date)}',
                    ),
                    trailing: Text('${hour.chance}% · ${hour.rain} mm'),
                  ),
              ],
            ),
          ],
          SectionTitle(l.xRainLog),
          AsyncBody(
            value: ref.watch(rainProvider),
            builder: (entries) => Column(
              children: [
                if (entries.isEmpty) Text(l.xEmpty),
                for (final e in entries)
                  ListTile(
                    title: Text(context.fmt.date(e.date)),
                    subtitle: Text(e.notes),
                    trailing: Text('${e.millimetres} mm'),
                    onTap: () => _rain(e),
                    onLongPress: () async {
                      if (await confirm(context, title: l.confirmDelete) &&
                          context.mounted) {
                        await perform(context, () async {
                          final db = ref.read(databaseProvider);
                          await (db.update(
                            db.rainEntries,
                          )..where((r) => r.id.equals(e.id))).write(
                            RainEntriesCompanion(
                              deleted: const Value(true),
                              updatedAt: Value(DateTime.now()),
                            ),
                          );
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
