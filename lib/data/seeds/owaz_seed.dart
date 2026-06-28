import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Seeds the database with data imported from owaz.atlas (test database dump).
/// Call once after DB is created — checks if already seeded first.
Future<void> seedOwazData(AppDatabase db) async {
  // Guard: skip if products already exist
  final existing = await db.getAllProducts();
  if (existing.isNotEmpty) return;

  // ── 1. Categories ──────────────────────────────────────────────────────────
  final catColors = {
    'Coffee':     '#E8724A',
    'Tea':        '#4CAF50',
    'Matcha':     '#66BB6A',
    'Smoothie':   '#AB47BC',
    'Milk Shakes':'#42A5F5',
    'Fresh':      '#FF7043',
    'Mojito':     '#26C6DA',
    'Cookies':    '#FFA726',
  };

  final Map<int, int> catIdMap = {}; // old_id → new_id
  final catData = [
    (12, 'Coffee'),
    (13, 'Tea'),
    (14, 'Matcha'),
    (15, 'Smoothie'),
    (16, 'Milk Shakes'),
    (17, 'Fresh'),
    (18, 'Mojito'),
    (19, 'Cookies'),
  ];

  for (final (oldId, name) in catData) {
    final newId = await db.createCategory(CategoriesCompanion.insert(
      name: name,
      color: Value(catColors[name] ?? '#E8724A'),
    ));
    catIdMap[oldId] = newId;
  }

  // ── 2. Units ───────────────────────────────────────────────────────────────
  // ── 3. Ingredients ─────────────────────────────────────────────────────────
  // (id, name, unit, stock, cost, minStock)
  final Map<int, int> ingIdMap = {}; // old_id → new_id
  final ingData = [
    (1,  'Kofe Sabazz',          'g',   618.0,  0.32, 150.0),
    (2,  'Banan',                'g',   1050.0, 0.54, 200.0),
    (3,  'Kiwi',                 'g',   800.0,  0.84, 200.0),
    (4,  'Klubnika',             'g',   300.0,  0.35, 200.0),
    (5,  'Sok Wisnya',           'ml',  500.0,  0.01, 200.0),
    (6,  'Sok Multifruit',       'ml',  500.0,  0.01, 200.0),
    (7,  'Sok Apple',            'ml',  500.0,  0.01, 200.0),
    (8,  'Sok Orange',           'ml',  500.0,  0.01, 200.0),
    (9,  'Myata',                'pcs', 30.0,   0.30, 5.0),
    (10, 'Sliwki',               'g',   250.0,  0.08, 100.0),
    (11, 'Cay gara "Ahmad"',     'pcs', 10.0,   1.40, 5.0),
    (12, 'Cay gok "Ahmad"',      'pcs', 10.0,   1.40, 5.0),
    (13, 'Limon',                'pcs', 20.0,   1.30, 5.0),
    (14, 'Morojny',              'g',   3000.0, 0.04, 1000.0),
    (15, 'Sirop Yagodny',        'ml',  500.0,  0.09, 100.0),
    (16, 'Sirop Vanil',          'ml',  500.0,  0.09, 100.0),
    (17, 'Sirop Klubnika',       'ml',  500.0,  0.09, 100.0),
    (18, 'Sirop Kiwi',           'ml',  500.0,  0.09, 100.0),
    (19, 'Sirop Chocolate',      'ml',  500.0,  0.09, 100.0),
    (20, 'Sirop Karamel',        'ml',  500.0,  0.09, 100.0),
    (21, 'Sirop Sol.Karamel',    'ml',  500.0,  0.09, 100.0),
    (22, 'Suyt',                 'ml',  2000.0, 0.02, 500.0),
    (23, 'Buz',                  'g',   5000.0, 0.01, 1000.0),
    (24, 'Chocolate',            'g',   900.0,  0.11, 100.0),
    (25, 'Orange',               'pcs', 20.0,   1.00, 5.0),
    (26, 'Oreo',                 'pcs', 10.0,   1.70, 5.0),
    (27, 'Imbir',                'g',   287.0,  0.53, 50.0),
    (28, 'Powrize',              'ml',  3500.0, 0.01, 1000.0),
    (29, 'Zamorojenny yagody',   'g',   500.0,  0.05, 100.0),
    (30, 'Tonic',                'ml',  330.0,  0.03, 100.0),
    (31, 'Sgusyonka',            'g',   450.0,  0.05, 100.0),
    (32, 'Matcha',               'g',   260.0,  0.60, 100.0),
    (33, 'San Sebastian',        'pcs', 5.0,   25.00, 1.0),
    (34, 'Cheesecake Classik',   'pcs', 2.0,   25.00, 1.0),
    (35, 'Cheesecake Snickers',  'pcs', 2.0,   25.00, 1.0),
    (36, 'Trifle cups Chocolate','pcs', 2.0,    7.00, 1.0),
    (37, 'Trifle cups Fruity',   'pcs', 2.0,    7.00, 1.0),
    (38, 'Choux Chocolate',      'pcs', 3.0,   10.00, 1.0),
    (39, 'Choux Classic',        'pcs', 1.0,   10.00, 1.0),
    (40, 'Cay Kur',              'g',   800.0,  0.17, 200.0),
  ];

  for (final (oldId, name, unit, stock, cost, minStock) in ingData) {
    final newId = await db.createIngredient(IngredientsCompanion.insert(
      name: name,
      unit: Value(unit),
      stock: Value(stock),
      cost: Value(cost),
      minStock: Value(minStock),
    ));
    ingIdMap[oldId] = newId;
  }

  // ── 4. Products ────────────────────────────────────────────────────────────
  // (old_id, name, sku, price, cost, old_cat_id)
  final Map<int, int> prodIdMap = {}; // old_id → new_id
  final prodData = [
    (52, 'Espresso',             '0001', 20.0,  3.20,  12),
    (56, 'Americano',            '0003', 20.0,  3.20,  12),
    (57, 'Ice Americano',        '0004', 20.0,  7.26,  12),
    (58, 'Americano Double',     '0005', 25.0,  5.76,  12),
    (59, 'Cappuccino',           '0006', 30.0,  6.80,  12),
    (60, 'Ice Latte',            '0007', 30.0,  8.30,  12),
    (61, 'Latte',                '0008', 30.0,  6.80,  12),
    (62, 'Flat White',           '0009', 35.0,  7.76,  12),
    (63, 'Raf',                  '0010', 35.0, 15.00,  12),
    (64, 'Mocha',                '0012', 35.0,  8.50,  12),
    (65, 'Hot Chocolate',        '0013', 35.0,  8.90,  12),
    (66, 'Bumble',               '0014', 35.0, 10.11,  12),
    (67, 'Tonic Espresso',       '0015', 40.0, 15.66,  12),
    (68, 'Glasse',               '0016', 35.0, 12.20,  12),
    (70, 'Frappe',               '0017', 35.0, 13.26,  12),
    (71, 'Affogato',             '0018', 40.0,  7.20,  12),
    (72, 'Spanish Latte',        '0019', 35.0,  8.70,  12),
    (73, 'Espresso Double',      '0002', 25.0,  5.76,  12),
    (77, 'San Sebastian',        '0025', 40.0, 25.00,  19),
    (78, 'Cheesecake Classic',   '0026', 40.0, 25.00,  19),
    (79, 'Cheesecake Snickers',  '0027', 40.0, 25.00,  19),
    (81, 'Choux Classic',        '0029', 20.0, 10.00,  19),
    (82, 'Choux Chocolate',      '0030', 20.0, 10.00,  19),
    (83, 'Trifle Cups Chocolate','0031', 15.0,  7.00,  19),
    (84, 'Trifle Cups Fruity',   '0032', 15.0,  7.00,  19),
  ];

  for (final (oldId, name, sku, price, cost, oldCatId) in prodData) {
    final newId = await db.createProduct(ProductsCompanion.insert(
      name: name,
      sku: sku,
      categoryId: Value(catIdMap[oldCatId]),
      price: Value(price),
      purchasePrice: Value(cost),
      quantity: const Value(0),
      useRecipeCost: const Value(true),
      recipeCalculatedCost: Value(cost),
    ));
    prodIdMap[oldId] = newId;
  }

  // ── 5. Recipes ─────────────────────────────────────────────────────────────
  // (old_product_id, old_ingredient_id, quantity)
  final recipeData = [
    (52, 1,  10.0),
    (56, 1,  10.0),
    (57, 1,  18.0),  (57, 23, 150.0),
    (58, 1,  18.0),
    (59, 1,  10.0),  (59, 22, 180.0),
    (60, 1,  10.0),  (60, 22, 180.0),  (60, 23, 150.0),
    (61, 1,  10.0),  (61, 22, 180.0),
    (62, 1,  18.0),  (62, 22, 100.0),
    (63, 1,  10.0),  (63, 22, 100.0),  (63, 10, 100.0),  (63, 16, 20.0),
    (64, 1,  10.0),  (64, 24,  30.0),  (64, 22, 100.0),
    (65, 24, 50.0),  (65, 22, 170.0),
    (66, 1,  18.0),  (66,  8, 150.0),  (66, 20,  15.0),  (66, 23, 150.0),
    (67, 1,  18.0),  (67, 30, 200.0),  (67, 13,   3.0),
    (68, 1,  10.0),  (68, 14, 150.0),  (68, 22, 150.0),
    (70, 1,  18.0),  (70, 22, 100.0),  (70, 14, 100.0),  (70, 23, 150.0),
    (71, 1,  10.0),  (71, 14, 100.0),
    (72, 1,  10.0),  (72, 31,  30.0),  (72, 22, 200.0),
    (73, 1,  18.0),
    (77, 33,  1.0),
    (78, 34,  1.0),
    (79, 35,  1.0),
    (81, 39,  1.0),
    (82, 38,  1.0),
    (83, 36,  1.0),
    (84, 37,  1.0),
  ];

  for (final (oldProdId, oldIngId, qty) in recipeData) {
    final newProdId = prodIdMap[oldProdId];
    final newIngId  = ingIdMap[oldIngId];
    if (newProdId == null || newIngId == null) continue;
    await db.createRecipe(RecipesCompanion.insert(
      productId: newProdId,
      ingredientId: newIngId,
      quantity: qty,
    ));
  }

  // Recalculate all product costs from recipes
  for (final oldId in prodIdMap.keys) {
    final newId = prodIdMap[oldId]!;
    await db.recalculateAndSaveRecipeCost(newId);
  }
}
