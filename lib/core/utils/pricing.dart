import '../../data/database/app_database.dart';

/// Единая точка расчёта цены товара с учётом его скидки.
/// Заменяет одинаковые вычисления, которые раньше были продублированы в
/// CartItem, ProductGrid, ProductTable и AppDatabase.
extension ProductPricing on Product {
  double get discountedPrice {
    if (discountType == 'percentage') {
      return (price - price * discount / 100).clamp(0, double.infinity);
    }
    // 'fixed' и любые неизвестные типы считаем фиксированной скидкой
    return (price - discount).clamp(0, double.infinity);
  }
}

/// Разбор пользовательского ввода скидки: "10" → 10 TMT, "10%" → 10% от [base].
/// Результат всегда в диапазоне [0, base].
double parseDiscountInput(String text, double base) {
  final t = text.trim();
  if (t.endsWith('%')) {
    final pct = double.tryParse(t.substring(0, t.length - 1)) ?? 0;
    return (base * pct / 100).clamp(0.0, base);
  }
  return (double.tryParse(t) ?? 0).clamp(0.0, base);
}
