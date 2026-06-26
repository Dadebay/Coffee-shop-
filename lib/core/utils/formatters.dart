import 'package:intl/intl.dart';

String formatCurrency(double amount, {String symbol = 'TMT'}) {
  return '${NumberFormat('#,##0.00').format(amount)} $symbol';
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String formatWeight(double value, String unit) {
  if (value >= 1000 && unit == 'g') {
    return '${(value / 1000).toStringAsFixed(2)} kg';
  }
  if (value >= 1000 && unit == 'ml') {
    return '${(value / 1000).toStringAsFixed(2)} L';
  }
  return '${value.toStringAsFixed(2)} $unit';
}
