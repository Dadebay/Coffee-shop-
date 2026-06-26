import 'package:get/get.dart';
import '../data/database/app_database.dart';
import 'database_controller.dart';

class RecipesController extends GetxController {
  static RecipesController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final RxList<Product> products = <Product>[].obs;
  final RxList<Ingredient> allIngredients = <Ingredient>[].obs;
  final Rx<Product?> selectedProduct = Rx<Product?>(null);
  final RxList<Recipe> recipes = <Recipe>[].obs;
  final RxDouble totalCost = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    products.value = await _db.getAllProducts();
    allIngredients.value = await _db.getAllIngredients();
  }

  Future<void> selectProduct(Product p) async {
    selectedProduct.value = p;
    await _loadRecipes(p.id);
  }

  Future<void> _loadRecipes(int productId) async {
    recipes.value = await _db.getRecipesForProduct(productId);
    totalCost.value = await _db.calculateRecipeCost(productId);
  }

  Future<void> addIngredient(int ingredientId, double qty) async {
    final p = selectedProduct.value;
    if (p == null) return;
    await _db.createRecipe(RecipesCompanion.insert(
      productId: p.id,
      ingredientId: ingredientId,
      quantity: qty,
    ));
    await _db.recalculateAndSaveRecipeCost(p.id);
    await _loadRecipes(p.id);
  }

  Future<void> updateRecipeQty(Recipe recipe, double qty) async {
    await _db.updateRecipe(recipe.copyWith(quantity: qty));
    await _db.recalculateAndSaveRecipeCost(selectedProduct.value!.id);
    await _loadRecipes(selectedProduct.value!.id);
  }

  Future<void> removeRecipe(int recipeId) async {
    await _db.deleteRecipe(recipeId);
    await _db.recalculateAndSaveRecipeCost(selectedProduct.value!.id);
    await _loadRecipes(selectedProduct.value!.id);
  }

  Ingredient? ingredientById(int id) {
    try {
      return allIngredients.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
