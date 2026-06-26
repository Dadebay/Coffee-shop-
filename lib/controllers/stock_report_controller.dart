import 'package:get/get.dart';
import 'database_controller.dart';
import '../../data/database/app_database.dart';

class StockReportController extends GetxController {
  static StockReportController get to => Get.find();
  final _db = Get.find<DatabaseController>().db;

  // ── State ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxList<Product> allProducts = <Product>[].obs;
  final RxList<Ingredient> criticalIngredients = <Ingredient>[].obs;
  
  // Filter state
  final RxString filterType = 'all'.obs; // all | critical | expiring | expired | zero

  @override
  void onInit() {
    super.onInit();
    loadReportData();
  }

  Future<void> loadReportData() async {
    isLoading.value = true;
    try {
      summary.value = await _db.getStockSummary();
      allProducts.value = await _db.getAllProducts();
      criticalIngredients.value = await _db.getCriticalStockIngredients();
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    filterType.value = filter;
  }

  List<Product> get filteredProducts {
    final now = DateTime.now();
    final in7Days = now.add(const Duration(days: 7));
    
    return allProducts.where((p) {
      switch (filterType.value) {
        case 'zero':
          return p.quantity == 0;
        case 'expired':
          return p.expireDate != null && p.expireDate!.isBefore(now);
        case 'expiring':
          return p.expireDate != null && p.expireDate!.isAfter(now) && p.expireDate!.isBefore(in7Days);
        case 'all':
        default:
          return true;
      }
    }).toList();
  }
}
