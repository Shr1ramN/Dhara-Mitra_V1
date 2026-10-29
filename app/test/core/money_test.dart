import 'package:dhara_mitra/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupIndian', () {
    test('groups the last three digits, then pairs', () {
      expect(groupIndian(0), '0');
      expect(groupIndian(999), '999');
      expect(groupIndian(1000), '1,000');
      expect(groupIndian(462480), '4,62,480');
      expect(groupIndian(123456789), '12,34,56,789');
      expect(groupIndian(-150000), '-1,50,000');
    });
  });

  group('formatRupees', () {
    test('formats paise as whole rupees', () {
      expect(formatRupees(rupees(462480)), '₹4,62,480');
      expect(formatRupees(rupees(8401)), '₹8,401');
      expect(formatRupees(0), '₹0');
    });

    test('rounds to the nearest rupee', () {
      expect(formatRupees(149), '₹1');
      expect(formatRupees(150), '₹2');
    });

    test('shows paise only when asked and present', () {
      expect(formatRupees(75050, showPaise: true), '₹750.50');
      expect(formatRupees(75000, showPaise: true), '₹750');
    });

    test('negative amounts use a minus sign', () {
      expect(formatRupees(rupees(-2000)), '−₹2,000');
    });
  });

  group('formatLakh', () {
    test('two decimals, trailing zeros dropped', () {
      expect(formatLakh(rupees(462480), 'L'), '₹4.62 L');
      expect(formatLakh(rupees(250000), 'L'), '₹2.5 L');
      expect(formatLakh(rupees(100000), 'L'), '₹1 L');
      expect(formatLakh(rupees(609329), 'ಲಕ್ಷ'), '₹6.09 ಲಕ್ಷ');
    });

    test('rounds half up on the second decimal', () {
      expect(formatLakh(rupees(236500), 'L'), '₹2.37 L');
      expect(formatLakh(rupees(236499), 'L'), '₹2.36 L');
    });
  });

  test('formatMoneyCompact switches to lakh from ₹1 lakh', () {
    expect(formatMoneyCompact(rupees(99999), 'L'), '₹99,999');
    expect(formatMoneyCompact(rupees(100000), 'L'), '₹1 L');
  });

  group('parseRupees', () {
    test('accepts commas, symbol, spaces and decimals', () {
      expect(parseRupees('1,300'), 130000);
      expect(parseRupees('₹ 1300.5'), 130050);
      expect(parseRupees('7'), 700);
    });

    test('rejects empty and junk', () {
      expect(parseRupees(''), isNull);
      expect(parseRupees('abc'), isNull);
    });
  });

  test('paiseToInput round-trips', () {
    expect(paiseToInput(130000), '1300');
    expect(paiseToInput(750), '7.5');
    expect(paiseToInput(null), '');
    expect(parseRupees(paiseToInput(130050)), 130050);
  });
}
