import 'money.dart';

/// 1850 → "1,850", 2.5 → "2.5", 2.25 → "2.25".
String formatQty(num value, {int maxDecimals = 2}) {
  if (value.isNaN || value.isInfinite) return '—';
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(maxDecimals);
  final parts = fixed.split('.');
  var frac = parts.length > 1 ? parts[1] : '';
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  final whole = groupIndian(int.parse(parts[0]));
  return '${negative ? '-' : ''}$whole${frac.isEmpty ? '' : '.$frac'}';
}

double? parseQty(String input) {
  final cleaned = input.replaceAll(RegExp(r'[,\s]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

String qtyToInput(num? value) =>
    value == null ? '' : formatQty(value).replaceAll(',', '');

const int guntasPerAcre = 40;

/// 2.7 acres → (2, 28): 2 acres 28 guntas.
(int acres, int guntas) toAcresGuntas(double acres) {
  final totalGuntas = (acres * guntasPerAcre).round();
  return (totalGuntas ~/ guntasPerAcre, totalGuntas % guntasPerAcre);
}

double fromAcresGuntas(int acres, int guntas) => acres + guntas / guntasPerAcre;
