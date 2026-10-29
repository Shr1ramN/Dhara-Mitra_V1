import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Returns a dialable Indian number, or null when the number/type is invalid.
String? indianPhone(String input, {bool landline = false}) {
  final value = input.trim();
  if (value.isEmpty || !RegExp(r'^[+0-9 ()-]+$').hasMatch(value)) return null;
  try {
    final number = PhoneNumber.parse(value, callerCountry: IsoCode.IN);
    if (number.isoCode != IsoCode.IN ||
        number.nsn.length != 10 ||
        !number.isValid(
          type: landline ? PhoneNumberType.fixedLine : PhoneNumberType.mobile,
        )) {
      return null;
    }
    return number.international;
  } catch (_) {
    return null;
  }
}
