import '../../core/utils/pricing.dart';
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

  double get unitPrice => product.discountedPrice;

  double get lineTotal => (unitPrice * quantity - extraDiscount).clamp(0, double.infinity);

  double get cost => product.useRecipeCost ? product.recipeCalculatedCost : product.purchasePrice;

  double get netProfit => (unitPrice - cost) * quantity;
}
