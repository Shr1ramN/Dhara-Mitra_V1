class FarmException implements Exception {
  const FarmException(this.code);
  final String code;
  @override
  String toString() => code;
}

void require(bool condition, [String code = 'invalid']) {
  if (!condition) throw FarmException(code);
}

void positive(num value) => require(value.isFinite && value > 0, 'positive');
void nonNegative(num value) => require(value.isFinite && value >= 0);
