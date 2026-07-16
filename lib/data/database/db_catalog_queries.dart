part of 'app_database.dart';

/// Products, categories, units, ingredients, recipes, users.
extension CatalogQueries on AppDatabase {
  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<Product>> getActiveProducts({int? categoryId, String? search}) {
    final query = select(products)
      ..where((p) => p.status.equals(true));
    if (categoryId != null) {
      query.where((p) => p.categoryId.equals(categoryId));
    }
    if (search != null && search.isNotEmpty) {
      query.where((p) => p.name.like('%$search%') | p.sku.like('%$search%'));
    }
    query.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.get();
  }

  Future<List<Product>> getAllProducts() =>
      (select(products)..orderBy([(p) => OrderingTerm.asc(p.name)])).get();

  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> createProduct(ProductsCompanion data) => into(products).insert(data);

  Future<bool> updateProduct(Product product) => update(products).replace(product);

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Future<int> createCategory(CategoriesCompanion data) => into(categories).insert(data);

  Future<bool> updateCategory(Category cat) => update(categories).replace(cat);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // ── Ingredients ───────────────────────────────────────────────────────────

  Future<List<Ingredient>> getAllIngredients() =>
      (select(ingredients)..orderBy([(i) => OrderingTerm.asc(i.name)])).get();

  Future<List<Ingredient>> getLowStockIngredients() async {
    final all = await getAllIngredients();
    return all.where((i) => i.minStock > 0 && i.stock <= i.minStock).toList();
  }

  Future<int> createIngredient(IngredientsCompanion data) => into(ingredients).insert(data);

  Future<bool> updateIngredient(Ingredient ingredient) => update(ingredients).replace(ingredient);

  Future<void> adjustIngredientStock(int id, double delta) async {
    await customUpdate(
      'UPDATE ingredients SET stock = MAX(0, stock + ?) WHERE id = ?',
      variables: [Variable.withReal(delta), Variable.withInt(id)],
      updates: {ingredients},
    );
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  Future<List<Recipe>> getRecipesForProduct(int productId) =>
      (select(recipes)..where((r) => r.productId.equals(productId))).get();

  /// Returns all products that use [ingredientId] in their recipe.
  Future<List<Product>> getProductsUsingIngredient(int ingredientId) async {
    final recipeRows = await (select(recipes)
          ..where((r) => r.ingredientId.equals(ingredientId)))
        .get();
    if (recipeRows.isEmpty) return [];
    final productIds = recipeRows.map((r) => r.productId).toSet().toList();
    return (select(products)
          ..where((p) => p.id.isIn(productIds)))
        .get();
  }

  /// How many units of [productId] can be made from current ingredient stock.
  /// Returns -1 if the product has no recipe (no constraint).
  Future<int> getMaxProducible(int productId) async {
    final prodRecipes = await getRecipesForProduct(productId);
    if (prodRecipes.isEmpty) return -1;
    final stock = {for (final i in await getAllIngredients()) i.id: i.stock};
    return _maxFromRecipes(prodRecipes, stock);
  }

  /// Batch version of [getMaxProducible]: computes the max for every product
  /// that has a recipe in just two queries, instead of 2 queries per product.
  /// Products without recipes are absent from the map (callers use -1).
  Future<Map<int, int>> getMaxProducibleMap() async {
    final allRecipes = await getAllRecipes();
    final stock = {for (final i in await getAllIngredients()) i.id: i.stock};

    final byProduct = <int, List<Recipe>>{};
    for (final r in allRecipes) {
      byProduct.putIfAbsent(r.productId, () => []).add(r);
    }
    return byProduct.map(
        (productId, rows) => MapEntry(productId, _maxFromRecipes(rows, stock)));
  }

  int _maxFromRecipes(List<Recipe> rows, Map<int, double> stock) {
    int max = 99999;
    for (final r in rows) {
      if (r.quantity <= 0) continue;
      final ingStock = stock[r.ingredientId];
      if (ingStock == null) continue; // orphaned recipe row — no constraint
      final fromThis = (ingStock / r.quantity).floor();
      if (fromThis < max) max = fromThis;
    }
    return max == 99999 ? -1 : max;
  }

  Future<List<Recipe>> getAllRecipes() => select(recipes).get();

  Future<int> createRecipe(RecipesCompanion data) => into(recipes).insert(data);

  Future<bool> updateRecipe(Recipe recipe) => update(recipes).replace(recipe);

  Future<int> deleteRecipe(int id) =>
      (delete(recipes)..where((r) => r.id.equals(id))).go();

  Future<void> deleteRecipesForProduct(int productId) =>
      (delete(recipes)..where((r) => r.productId.equals(productId))).go();

  // ── Recipe cost calculation ────────────────────────────────────────────────

  Future<double> calculateRecipeCost(int productId) async {
    final prodRecipes = await getRecipesForProduct(productId);
    double total = 0;
    for (final recipe in prodRecipes) {
      final ing = await (select(ingredients)..where((i) => i.id.equals(recipe.ingredientId)))
          .getSingleOrNull();
      if (ing != null) total += recipe.quantity * ing.cost;
    }
    return total;
  }

  Future<void> recalculateAndSaveRecipeCost(int productId) async {
    final cost = await calculateRecipeCost(productId);
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(recipeCalculatedCost: Value(cost), useRecipeCost: const Value(true)),
    );
  }

  // ── Units ─────────────────────────────────────────────────────────────────

  Future<List<Unit>> getAllUnits() => select(units).get();

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<User?> getUserByPin(String pin) =>
      (select(users)..where((u) => u.pin.equals(pin) & u.isActive.equals(true)))
          .getSingleOrNull();

  Future<List<User>> getAllUsers() =>
      (select(users)..orderBy([(u) => OrderingTerm.asc(u.name)])).get();

  Future<int> createUser(UsersCompanion data) => into(users).insert(data);

  Future<bool> updateUser(User user) => update(users).replace(user);
}
