import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Keep later features compiled and their stored data intact.
const v1 = true;

String v1Text(BuildContext context, String en, String kn) =>
    Localizations.localeOf(context).languageCode == 'kn' ? kn : en;

class EntryDate extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void select(DateTime? value) => state = value;
}

final entryDateProvider = NotifierProvider<EntryDate, DateTime?>(EntryDate.new);
final entryDayProvider = Provider<DateTime>(
  (ref) => ref.watch(entryDateProvider) ?? ref.watch(todayProvider),
);
