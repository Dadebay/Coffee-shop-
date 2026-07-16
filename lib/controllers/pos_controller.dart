import 'package:get/get.dart';
import '../data/database/app_database.dart';
import 'database_controller.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';

class PosController extends GetxController {
  static PosController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final RxList<Product> products = <Product>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final Rx<int?> selectedCategory = Rx<int?>(null);
  final RxString search = ''.obs;
  final RxBool loadingProducts = false.obs;
  final RxMap<int, int> maxProducible = <int, int>{}.obs; // productId → max count (-1 = no recipe)

  // Cached for live adjustment
  final RxList<Ingredient> _ingredients = <Ingredient>[].obs;
  final RxMap<int, List<Recipe>> _productRecipes = <int, List<Recipe>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    ever(selectedCategory, (_) => loadProducts());
    debounce(search, (_) => loadProducts(), time: const Duration(milliseconds: 300));
    loadProducts();
  }

  Future<void> loadCategories() async {
    categories.value = await _db.getAllCategories();
  }

  Future<void> loadProducts() async {
    loadingProducts.value = true;
    products.value = await _db.getActiveProducts(
      categoryId: selectedCategory.value,
      search: search.value.isEmpty ? null : search.value,
    );
    loadingProducts.value = false;
    await _calcMaxProducible();
  }

  Future<void> _calcMaxProducible() async {
    // Load all ingredients and recipes once (3 queries total, was 2 per product)
    _ingredients.value = await _db.getAllIngredients();
    final allRecipes = await _db.getAllRecipes();
    final recipeMap = <int, List<Recipe>>{for (final p in products) p.id: []};
    for (final r in allRecipes) {
      recipeMap[r.productId]?.add(r);
    }
    _productRecipes.value = recipeMap;

    final maxMap = await _db.getMaxProducibleMap();
    maxProducible.value = {
      for (final p in products) p.id: maxMap[p.id] ?? -1,
    };
  }

  /// Returns maxProducible adjusted for ingredient consumption in [cartQtys].
  /// cartQtys: productId → quantity in cart
  Map<int, int> calcAdjustedMax(Map<int, int> cartQtys) {
    if (cartQtys.isEmpty || _ingredients.isEmpty) return Map.from(maxProducible);

    // Total ingredient consumption from cart
    final ingConsumed = <int, double>{};
    for (final entry in cartQtys.entries) {
      final recipes = _productRecipes[entry.key] ?? [];
      for (final r in recipes) {
        ingConsumed[r.ingredientId] = (ingConsumed[r.ingredientId] ?? 0) + r.quantity * entry.value;
      }
    }

    // Adjusted stock per ingredient
    final ingStock = <int, double>{for (final i in _ingredients) i.id: i.stock};
    final adjStock = <int, double>{};
    for (final entry in ingStock.entries) {
      adjStock[entry.key] = entry.value - (ingConsumed[entry.key] ?? 0);
    }

    // Recalculate max for each product from adjusted stock
    final result = <int, int>{};
    for (final p in products) {
      final recipes = _productRecipes[p.id] ?? [];
      if (recipes.isEmpty) {
        result[p.id] = maxProducible[p.id] ?? -1;
      } else {
        int max = 99999;
        for (final r in recipes) {
          if (r.quantity <= 0) continue;
          final stock = adjStock[r.ingredientId] ?? 0;
          final fromThis = (stock / r.quantity).floor();
          if (fromThis < max) max = fromThis;
        }
        result[p.id] = max == 99999 ? -1 : max.clamp(0, 99999);
      }
    }
    return result;
  }

  void selectCategory(int? id) => selectedCategory.value = id;

  Future<Order> placeOrder({
    required double paid,
    required String paymentMethod,
    required double orderDiscount,
  }) async {
    final cart = CartController.to;
    final user = AuthController.to.currentUser.value;
    if (user == null) throw Exception('Kullanıcı bulunamadı');
    if (cart.items.isEmpty) throw Exception('Sepet boş');

    final order = await _db.placeOrder(
      userId: user.id,
      cartItems: cart.items
          .map((i) => {
                'product': i.product,
                'quantity': i.quantity,
                'discount': i.extraDiscount,
              })
          .toList(),
      orderDiscount: orderDiscount,
      paid: paid,
      paymentMethod: paymentMethod,
    );

    cart.clear();
    await loadProducts();
    return order;
  }
}
