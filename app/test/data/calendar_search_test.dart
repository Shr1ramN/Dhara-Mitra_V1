import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarRecord record(
  String title, {
  String category = 'activity',
  String notes = '',
}) => CalendarRecord('id', DateTime(2026, 10, 29), category, title, notes, '/');

void main() {
  test('search keeps all terms alongside synonyms', () {
    final query = RecordQuery('sales Ravi');
    expect(query.matches(record('Ravi', category: 'sale')), isTrue);
    expect(query.matches(record('Kumar', category: 'sale')), isFalse);
    expect(query.matches(record('Ravi', category: 'expense')), isFalse);
    expect(
      RecordQuery('MANURE north')
          .matches(record('ಗೊಬ್ಬರ', notes: 'North plot')),
      isTrue,
    );
    expect(
      RecordQuery('manure north').matches(record('manure south')),
      isFalse,
    );
  });

  test('latest uses complete words and handles conversational queries', () {
    expect(RecordQuery('blast treatment').latest, isFalse);
    expect(RecordQuery('when did I last put manure?').latest, isTrue);
    expect(
      RecordQuery('when did I last put manure?')
          .matches(record('Organic manure')),
      isTrue,
    );
    expect(RecordQuery('latest').matches(record('Irrigation')), isTrue);
    expect(RecordQuery('ಕೊನೆಯ ಗೊಬ್ಬರ').matches(record('manure')), isTrue);
  });

  test('synonyms respect word boundaries and unknown terms', () {
    expect(
      RecordQuery('expenses').matches(record('Fuel', category: 'expense')),
      isTrue,
    );
    expect(RecordQuery('for').matches(record('manure')), isFalse);
    expect(RecordQuery('water').matches(record('watermelon harvest')), isFalse);
    expect(RecordQuery('water').matches(record('Irrigation')), isTrue);
    expect(
      RecordQuery('spray Ravi').matches(record('spraying', notes: 'Ravi')),
      isTrue,
    );
    expect(RecordQuery('  unknown  ').matches(record('manure')), isFalse);
    expect(RecordQuery('   ').matches(record('manure')), isTrue);
  });

  test('range includes whole start and end calendar days', () {
    final start = DateTime(2026, 10, 20, 15);
    final end = DateTime(2026, 10, 29, 8);
    expect(calendarDateInRange(DateTime(2026, 10, 20), start, end), isTrue);
    expect(
      calendarDateInRange(DateTime(2026, 10, 29, 23, 59), start, end),
      isTrue,
    );
    expect(calendarDateInRange(DateTime(2026, 10, 30), start, end), isFalse);
    expect(
      calendarDateInRange(DateTime(2026, 10, 19, 23), start, end),
      isFalse,
    );
  });
}
