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
    _calcMaxProducible();
  }

  Future<void> _calcMaxProducible() async {
    final map = <int, int>{};
    for (final p in products) {
      map[p.id] = await _db.getMaxProducible(p.id);
    }
    maxProducible.value = map;
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
    return order;
  }
}
