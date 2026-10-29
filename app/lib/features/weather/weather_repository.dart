import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../core/db/database.dart';
import '../../core/dates.dart';
import '../../core/validation.dart';

class ForecastDay {
  const ForecastDay(
    this.date,
    this.minimum,
    this.maximum,
    this.rain,
    this.chance,
  );
  final DateTime date;
  final double minimum, maximum, rain;
  final int chance;
}

class ForecastHour {
  const ForecastHour(this.date, this.rain, this.chance);
  final DateTime date;
  final double rain;
  final int chance;
}

class Forecast {
  const Forecast(this.days, this.hours);
  final List<ForecastDay> days;
  final List<ForecastHour> hours;
  factory Forecast.parse(String payload) {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final daily = map['daily'] as Map<String, dynamic>;
    final hourly = map['hourly'] as Map<String, dynamic>;
    final dates = (daily['time'] as List<Object?>).cast<String>();
    final times = (hourly['time'] as List<Object?>).cast<String>();
    double number(Map<String, dynamic> data, String key, int index) {
      final list = data[key] as List<Object?>;
      final value = list[index];
      require(value is num && value.isFinite);
      return (value as num).toDouble();
    }

    require(dates.isNotEmpty && dates.length <= 16 && times.length <= 400);
    return Forecast(
      [
        for (var i = 0; i < dates.length; i++)
          ForecastDay(
            DateTime.parse(dates[i]),
            number(daily, 'temperature_2m_min', i),
            number(daily, 'temperature_2m_max', i),
            number(daily, 'precipitation_sum', i),
            number(daily, 'precipitation_probability_max', i).round(),
          ),
      ],
      [
        for (var i = 0; i < times.length; i++)
          ForecastHour(
            DateTime.parse('${times[i]}:00+05:30').toLocal(),
            number(hourly, 'precipitation', i),
            number(hourly, 'precipitation_probability', i).round(),
          ),
      ],
    );
  }
}

class WeatherRepository {
  WeatherRepository(this.db, {this._client});
  final AppDatabase db;
  final http.Client? _client;
  Stream<WeatherCache?> watch() => (db.select(
    db.weatherCaches,
  )..where((w) => w.key.equals('forecast'))).watchSingleOrNull();
  Future<void> refresh(double latitude, double longitude) async {
    require(
      latitude.isFinite &&
          longitude.isFinite &&
          latitude.abs() <= 90 &&
          longitude.abs() <= 180,
    );
    final client = _client ?? http.Client();
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
        'hourly': 'precipitation_probability,precipitation',
        'timezone': 'Asia/Kolkata',
        'forecast_days': '7',
      });
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      require(response.statusCode == 200, 'network');
      Forecast.parse(response.body);
      await db
          .into(db.weatherCaches)
          .insertOnConflictUpdate(
            WeatherCachesCompanion.insert(
              key: 'forecast',
              fetchedOn: DateTime.now(),
              latitude: latitude,
              longitude: longitude,
              payload: response.body,
            ),
          );
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<void> rain(DateTime day, double mm, {String notes = ''}) async {
    nonNegative(mm);
    require(mm <= 3000);
    final date = dateOnly(day);
    final old = await (db.select(
      db.rainEntries,
    )..where((r) => r.date.equals(date))).getSingleOrNull();
    await db
        .into(db.rainEntries)
        .insertOnConflictUpdate(
          RainEntriesCompanion.insert(
            id: old == null ? const Value.absent() : Value(old.id),
            date: date,
            millimetres: mm,
            notes: Value(notes.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
