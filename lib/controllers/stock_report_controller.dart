import 'package:get/get.dart';
import 'database_controller.dart';
import '../../data/database/app_database.dart';
import '../features/reports/export_service.dart';

class StockReportController extends GetxController {
  static StockReportController get to => Get.find();
  final _db = Get.find<DatabaseController>().db;

  // ── State ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxList<Product> allProducts = <Product>[].obs;
  final RxList<Ingredient> criticalIngredients = <Ingredient>[].obs;
  final RxMap<int, int> maxProducible = <int, int>{}.obs;

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
      final rawSummary = await _db.getStockSummary();
      allProducts.value = await _db.getAllProducts();
      criticalIngredients.value = await _db.getCriticalStockIngredients();

      // Compute maxProducible first so zeroStock is recipe-accurate
      final map = <int, int>{};
      for (final p in allProducts) {
        map[p.id] = await _db.getMaxProducible(p.id);
      }
      maxProducible.value = map;

      // zeroStock: use maxProducible if a recipe exists, else fallback to p.quantity
      int zeroStock = 0;
      double totalValue = 0;
      for (final p in allProducts) {
        final max = map[p.id] ?? -1;
        final effectiveQty = max >= 0 ? max : p.quantity;
        if (effectiveQty == 0) zeroStock++;
        totalValue += p.price * effectiveQty;
      }

      summary.value = {
        ...rawSummary,
        'zeroStock': zeroStock,
        'totalProductValue': totalValue,
      };
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
          final max = maxProducible[p.id] ?? -1;
          return (max >= 0 ? max : p.quantity) == 0;
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

  /// Returns `true` if the file was saved, `false` if the user cancelled
  /// the save dialog.
  Future<bool> exportMovements() async {
    final movements = await _db.getRecentTransactions(limit: 500);
    final ingredients = await _db.getAllIngredients();
    final namesMap = {for (final i in ingredients) i.id: i.name};
    final unitsMap = {for (final i in ingredients) i.id: i.unit};
    return ExportService.exportStockMovements(
      movements,
      ingredientsMap: namesMap,
      ingredientUnits: unitsMap,
    );
  }
}
