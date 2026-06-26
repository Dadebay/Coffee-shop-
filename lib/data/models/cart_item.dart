import '../database/app_database.dart';

class CartItem {
  final Product product;
  int quantity;
  double extraDiscount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.extraDiscount = 0,
  });

  double get unitPrice {
    double p = product.price;
    if (product.discountType == 'fixed') {
      p = (p - product.discount).clamp(0, double.infinity);
    } else if (product.discountType == 'percentage') {
      p = (p - p * product.discount / 100).clamp(0, double.infinity);
    }
    return p;
  }

  double get lineTotal => (unitPrice * quantity - extraDiscount).clamp(0, double.infinity);

  double get cost => product.useRecipeCost ? product.recipeCalculatedCost : product.purchasePrice;

  double get netProfit => (unitPrice - cost) * quantity;
}
