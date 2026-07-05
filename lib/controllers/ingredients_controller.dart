import 'package:drift/drift.dart' as drift;
import 'package:get/get.dart';
import '../data/database/app_database.dart';
import 'database_controller.dart';
import 'recipes_controller.dart';

class IngredientsController extends GetxController {
  static IngredientsController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final RxList<Ingredient> ingredients = <Ingredient>[].obs;
  final RxList<Ingredient> lowStock = <Ingredient>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    ingredients.value = await _db.getAllIngredients();
    lowStock.value = await _db.getLowStockIngredients();
    loading.value = false;
    if (Get.isRegistered<RecipesController>()) {
      Get.find<RecipesController>().loadData();
    }
  }

  Future<void> save({
    Ingredient? existing,
    required String name,
    required String unit,
    required double cost,
    required double stock,
    required double minStock,
  }) async {
    if (existing == null) {
      await _db.createIngredient(IngredientsCompanion.insert(
        name: name,
        unit: drift.Value(unit),
        cost: drift.Value(cost),
        stock: drift.Value(stock),
        minStock: drift.Value(minStock),
      ));
    } else {
      await _db.updateIngredient(existing.copyWith(
        name: name,
        unit: unit,
        cost: cost,
        stock: stock,
        minStock: minStock,
      ));
    }
    await loadAll();
  }

  Future<void> adjustStock(int id, double delta) async {
    await _db.adjustIngredientStock(id, delta);
    await loadAll();
  }
}
