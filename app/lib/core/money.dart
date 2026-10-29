/// Money is stored everywhere as whole paise (int) so sums never drift.
/// Display follows Indian grouping (F10.7): ₹4,62,480 and ₹4.62 L.
library;

const int paisePerRupee = 100;
const int paisePerLakh = 100000 * paisePerRupee;

int rupees(num value) => (value * paisePerRupee).round();

/// Groups digits the Indian way: 4,62,480 · 12,34,56,789.
String groupIndian(int value) {
  final digits = value.abs().toString();
  if (digits.length <= 3) return value < 0 ? '-$digits' : digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  final grouped = '${parts.join(',')},$last3';
  return value < 0 ? '-$grouped' : grouped;
}

/// ₹4,62,480 — rounded to the rupee unless [showPaise] and there are paise.
String formatRupees(int paise, {bool showPaise = false}) {
  final abs = paise.abs();
  final String body;
  if (showPaise && abs % paisePerRupee != 0) {
    body =
        '${groupIndian(abs ~/ paisePerRupee)}.${(abs % paisePerRupee).toString().padLeft(2, '0')}';
  } else {
    body = groupIndian((abs + paisePerRupee ~/ 2) ~/ paisePerRupee);
  }
  return paise < 0 ? '−₹$body' : '₹$body';
}

/// ₹4.62 L — [unit] is the localised word for lakh.
String formatLakh(int paise, String unit) {
  final hundredths =
      (paise.abs() + paisePerLakh ~/ 200) ~/ (paisePerLakh ~/ 100);
  final fracText = (hundredths % 100)
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  final whole = groupIndian(hundredths ~/ 100);
  final body = fracText.isEmpty ? whole : '$whole.$fracText';
  return '${paise < 0 ? '−' : ''}₹$body $unit';
}

/// Lakh format from ₹1 lakh upwards, rupees below that.
String formatMoneyCompact(int paise, String lakhUnit) =>
    paise.abs() >= paisePerLakh
    ? formatLakh(paise, lakhUnit)
    : formatRupees(paise);

/// Parses what the user typed ("1,300", "₹ 1300.50", "7") into paise.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return rupees(value);
}

/// Rupee text for an input field: 130000 paise → "1300", 750 → "7.5".
String paiseToInput(int? paise) {
  if (paise == null) return '';
  if (paise % paisePerRupee == 0) return '${paise ~/ paisePerRupee}';
  return (paise / paisePerRupee)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0$'), '');
}
