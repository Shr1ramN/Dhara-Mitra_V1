import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';

class CalendarRecord {
  const CalendarRecord(
    this.id,
    this.date,
    this.category,
    this.title,
    this.notes,
    this.route,
  );
  final String id, category, title, notes, route;
  final DateTime date;
}

/// Explicit vocabulary only; no network or inferred events.
class RecordQuery {
  RecordQuery(String input) : text = input.trim().toLowerCase();
  final String text;
  static const vocabulary = {
    'manure': ['manure', 'ಗೊಬ್ಬರ', 'ಕೊಟ್ಟಿಗೆ'],
    'fertiliser': [
      'fertiliser',
      'fertilizer',
      'fertilisers',
      'fertilizers',
      'ರಸಗೊಬ್ಬರ',
    ],
    'spray': ['spray', 'spraying', 'disease', 'ಸಿಂಪಡ', 'ರೋಗ'],
    'irrigation': ['irrigation', 'water', 'ನೀರು'],
    'harvest': ['harvest', 'harvests', 'ಕೊಯ್ಲು'],
    'attendance': ['attendance', 'ಹಾಜರಿ'],
    'expense': ['expense', 'expenses', 'ಖರ್ಚು'],
    'sale': ['sale', 'sales', 'ಮಾರಾಟ'],
    'payment': ['payment', 'payments', 'paid', 'ಪಾವತಿ'],
  };
  bool get latest =>
      RegExp(r'\b(last|latest|recent|newest)\b').hasMatch(text) ||
      text.contains('ಕೊನೆಯ') ||
      text.contains('ಕೊನೆಗೆ');
  String? get keyword {
    // Prefer precise fertilizer over the Kannada substring for manure.
    for (final key in [
      'fertiliser',
      ...vocabulary.keys.where((k) => k != 'fertiliser'),
    ]) {
      if (vocabulary[key]!.any(text.contains)) return key;
    }
    return null;
  }

  bool matches(CalendarRecord record) {
    if (text.isEmpty) return true;
    final haystack = '${record.category} ${record.title} ${record.notes}'
        .toLowerCase();
    final terms = text
        .split(RegExp(r'[\s,;.!?"“”]+'))
        .where((t) => t.isNotEmpty);
    const filler = {
      'when',
      'did',
      'i',
      'last',
      'latest',
      'recent',
      'newest',
      'put',
      'apply',
      'applied',
      'the',
      'a',
      'an',
      'was',
      'my',
      'show',
      'me',
      'records',
      'record',
      'of',
      'for',
      'ಕೊನೆಯ',
      'ಕೊನೆಗೆ',
    };
    final conversational =
        latest ||
        terms.any(
          (term) => vocabulary.values.any((aliases) => aliases.contains(term)),
        );
    return terms.where((t) => !conversational || !filler.contains(t)).every((
      term,
    ) {
      for (final aliases in vocabulary.values) {
        if (aliases.contains(term)) {
          return aliases.any((alias) => _contains(haystack, alias));
        }
      }
      return haystack.contains(term);
    });
  }

  static bool _contains(String text, String term) =>
      RegExp(r'^[a-z]+$').hasMatch(term)
      ? RegExp('\\b${RegExp.escape(term)}\\b').hasMatch(text)
      : text.contains(term);
}

DateTime calendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Date-only comparison includes entries at any time on the final day.
bool calendarDateInRange(DateTime date, DateTime start, DateTime end) {
  final value = calendarDay(date);
  return !value.isBefore(calendarDay(start)) &&
      !value.isAfter(calendarDay(end));
}

class CalendarRepository {
  CalendarRepository(this.db);
  final AppDatabase db;
  Stream<List<CalendarRecord>> watch() => db.watchAll(db.allTables, load);
  Future<List<CalendarRecord>> load() async {
    final rows = await db.customSelect('''
SELECT id, date AS day, 'activity' AS category, kind || ' ' || title AS title, notes, '/activity/' || id AS route FROM activities WHERE deleted = 0
UNION ALL SELECT id, date, 'expense', category, notes, '/expenses' FROM expenses WHERE deleted = 0
UNION ALL SELECT a.id, a.date, 'attendance', w.name || ' ' || a.status, a.work, '/labour?tab=attendance' FROM attendance_entries a JOIN workers w ON w.id=a.worker_id WHERE a.deleted=0
UNION ALL SELECT t.id, t.date, 'payment', w.name || ' ' || t.kind, t.note, '/worker/' || w.id FROM worker_txns t JOIN workers w ON w.id=t.worker_id WHERE t.deleted=0 AND t.kind != 'work'
UNION ALL SELECT id, harvested_on, 'harvest', 'areca ' || title, notes, '/lot/' || id FROM lots WHERE deleted=0
UNION ALL SELECT id, collected_on, 'harvest', 'areca collection', notes, '/collections' FROM areca_collections WHERE deleted=0
UNION ALL SELECT id, harvested_on, 'harvest', crop || ' ' || title, notes, '/produce' FROM produce_lots WHERE deleted=0
UNION ALL SELECT s.id, s.date, 'sale', 'areca ' || b.name, s.notes, '/sales' FROM sales s JOIN buyers b ON b.id=s.buyer_id WHERE s.deleted=0
UNION ALL SELECT s.id, s.date, 'sale', p.crop || ' ' || b.name, s.notes, '/sales' FROM produce_sales s JOIN buyers b ON b.id=s.buyer_id JOIN produce_lots p ON p.id=s.lot_id WHERE s.deleted=0
UNION ALL SELECT r.id, r.date, 'payment', b.name, r.notes, '/sales' FROM sale_receipts r JOIN sales s ON s.id=r.sale_id JOIN buyers b ON b.id=s.buyer_id WHERE r.deleted=0 AND r.produce=0 AND s.deleted=0
UNION ALL SELECT r.id, r.date, 'payment', b.name, r.notes, '/sales' FROM sale_receipts r JOIN produce_sales s ON s.id=r.sale_id JOIN buyers b ON b.id=s.buyer_id WHERE r.deleted=0 AND r.produce=1 AND s.deleted=0
UNION ALL SELECT id, due_on, 'note', title, notes, '/note/' || id FROM reminders WHERE deleted=0 AND kind='dateNote'
ORDER BY day DESC, id
''').get();
    return rows
        .map(
          (r) => CalendarRecord(
            r.read<String>('id'),
            r.read<DateTime>('day'),
            r.read<String>('category'),
            r.read<String>('title'),
            r.read<String>('notes'),
            r.read<String>('route'),
          ),
        )
        .toList();
  }
}

final calendarRecordsProvider = StreamProvider(
  (ref) => CalendarRepository(ref.watch(databaseProvider)).watch(),
);
