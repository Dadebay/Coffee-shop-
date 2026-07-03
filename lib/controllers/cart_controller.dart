import 'package:get/get.dart';
import '../data/database/app_database.dart';
import '../data/models/cart_item.dart';
import 'pos_controller.dart';

class CartController extends GetxController {
  static CartController get to => Get.find();

  final RxList<CartItem> items = <CartItem>[].obs;

  double get subTotal => items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
  double get totalItemDiscount => items.fold(0.0, (s, i) => s + i.extraDiscount);
  int get totalCount => items.fold(0, (s, i) => s + i.quantity);

  double totalAfterOrderDiscount(double orderDiscount) =>
      (subTotal - totalItemDiscount - orderDiscount).clamp(0.0, double.infinity);

  // -1 = no recipe (use product.quantity), >=0 = ingredient-based max
  int _effectiveMax(Product product) {
    if (!Get.isRegistered<PosController>()) return product.quantity;
    final mp = PosController.to.maxProducible[product.id];
    if (mp == null || mp < 0) return product.quantity;
    return mp;
  }

  void addProduct(Product product) {
    final max = _effectiveMax(product);
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      final item = items[idx];
      if (max < 0 || item.quantity < max) {
        items[idx] = CartItem(
          product: item.product,
          quantity: item.quantity + 1,
          extraDiscount: item.extraDiscount,
        );
        items.refresh();
      } else {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Stok Yetersiz', '${product.name} için stok limiti doldu',
              duration: const Duration(seconds: 2));
        }
      }
    } else {
      if (max != 0) {
        items.add(CartItem(product: product));
      } else {
        if (!Get.isSnackbarOpen) {
          Get.snackbar('Stok Yok', '${product.name} stokta bulunmuyor',
              duration: const Duration(seconds: 2));
        }
      }
    }
  }

  void increment(int productId) {
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    final item = items[idx];
    final max = _effectiveMax(item.product);
    if (max < 0 || item.quantity < max) {
      items[idx] = CartItem(
        product: item.product,
        quantity: item.quantity + 1,
        extraDiscount: item.extraDiscount,
      );
      items.refresh();
    }
  }

  void decrement(int productId) {
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    final item = items[idx];
    if (item.quantity > 1) {
      items[idx] = CartItem(
        product: item.product,
        quantity: item.quantity - 1,
        extraDiscount: item.extraDiscount,
      );
      items.refresh();
    } else {
      items.removeAt(idx);
    }
  }

  void setExtraDiscount(int productId, double discount) {
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    final item = items[idx];
    items[idx] = CartItem(
      product: item.product,
      quantity: item.quantity,
      extraDiscount: discount.clamp(0, item.unitPrice * item.quantity),
    );
    items.refresh();
  }

  void removeItem(int productId) {
    items.removeWhere((i) => i.product.id == productId);
  }

  void clear() => items.clear();
}
