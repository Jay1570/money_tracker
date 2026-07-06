/// Formats a number using Indian digit grouping (e.g. 118422 -> "1,18,422"),
/// which is what the last three digits stay together and every pair of
/// digits before that gets its own comma.
///
/// Decimals are only shown when the value isn't a whole number, matching
/// how amounts are displayed throughout the app (e.g. "10,011" for a whole
/// income total, but "1,18,422.37" for a running net worth figure).
String formatAmount(
  double value, {
  int decimalDigits = 2,
  bool alwaysShowDecimals = false,
}) {
  final isNegative = value < 0;
  final absValue = value.abs();

  final showDecimals =
      alwaysShowDecimals || absValue != absValue.roundToDouble();
  final fixed = showDecimals
      ? absValue.toStringAsFixed(decimalDigits)
      : absValue.toStringAsFixed(0);

  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

  return '${isNegative ? '-' : ''}$grouped$decimalPart';
}

String _groupIndian(String intPart) {
  if (intPart.length <= 3) return intPart;

  final last3 = intPart.substring(intPart.length - 3);
  final rest = intPart
      .substring(0, intPart.length - 3)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (m) => '${m[1]},',
      );

  return '$rest,$last3';
}
