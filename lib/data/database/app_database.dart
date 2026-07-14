import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../seeds/owaz_seed.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().withDefault(const Constant('#E8724A'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get shortName => text().withLength(min: 1, max: 10)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().withLength(min: 1, max: 50).unique()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get unitId => integer().nullable().references(Units, #id)();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get discountType => text().withDefault(const Constant('fixed'))(); // fixed | percentage
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  DateTimeColumn get expireDate => dateTime().nullable()();
  BoolColumn get status => boolean().withDefault(const Constant(true))();
  BoolColumn get useRecipeCost => boolean().withDefault(const Constant(false))();
  RealColumn get recipeCalculatedCost => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200).unique()();
  TextColumn get unit => text().withDefault(const Constant('g'))(); // g | ml | pcs
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get cost => real().withDefault(const Constant(0.0))(); // cost per unit
  RealColumn get minStock => real().withDefault(const Constant(0.0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantity => real()(); // quantity per 1 unit of product
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get pin => text().withLength(min: 4, max: 6)();
  TextColumn get role => text().withDefault(const Constant('cashier'))(); // admin | cashier
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get subTotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paid => real().withDefault(const Constant(0.0))();
  RealColumn get due => real().withDefault(const Constant(0.0))();
  TextColumn get note => text().nullable()();
  BoolColumn get isReturned => boolean().withDefault(const Constant(false))();
  IntColumn get status => integer().withDefault(const Constant(1))(); // 1=paid, 0=due
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot at time of sale
  RealColumn get price => real()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get subTotal => real()();
  RealColumn get total => real()();
  RealColumn get netProfit => real().withDefault(const Constant(0.0))();
}

class InventoryTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  TextColumn get type => text()(); // consume | restore | purchase | manual_adjust
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().withDefault(const Constant(0.0))(); // birim fiyat (prikhod için)
  TextColumn get referenceType => text().nullable()(); // order | purchase | manual
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ActionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get action => text()(); // sale | cancel | price_change | stock_adjust
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  RealColumn get openingCash => real().withDefault(const Constant(0.0))();
  RealColumn get closingCash => real().nullable()();
  IntColumn get orderCount => integer().withDefault(const Constant(0))();
  RealColumn get totalRevenue => real().withDefault(const Constant(0.0))();
  RealColumn get totalCash => real().withDefault(const Constant(0.0))();
  RealColumn get totalCard => real().withDefault(const Constant(0.0))();
  BoolColumn get isOpen => boolean().withDefault(const Constant(true))();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Categories,
  Units,
  Products,
  Ingredients,
  Recipes,
  Users,
  Orders,
  OrderItems,
  InventoryTransactions,
  ActionLogs,
  Shifts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedInitialData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(products, products.imagePath);
          }
          if (from < 3) {
            await m.createTable(shifts);
          }
          if (from < 4) {
            await m.addColumn(inventoryTransactions, inventoryTransactions.unitCost);
          }
        },
      );

  Future<void> _seedInitialData() async {
    // Guard: skip if already seeded
    final existingUsers = await select(users).get();
    if (existingUsers.isNotEmpty) return;

    // Admin user
    await into(users).insert(UsersCompanion.insert(
      name: 'Admin',
      pin: '1234',
      role: const Value('admin'),
    ));

    // Units
    for (final (name, short) in [
      ('Adet', 'pcs'),
      ('Gram', 'g'),
      ('Mililitre', 'ml'),
      ('Litre', 'L'),
    ]) {
      await into(units).insert(UnitsCompanion.insert(name: name, shortName: short));
    }

    // Owaz.atlas products, categories, ingredients, recipes
    await seedOwazData(this);
  }

  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'kassa_db',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.dart.js'),
          onResult: (result) {
            if (result.missingFeatures.isNotEmpty) {
              // Running with limited storage — acceptable for dev
            }
          },
        ),
      );
    }
    // Native (Windows/macOS/Linux): store database next to the executable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final dbPath = p.join(exeDir, 'kassa_db.sqlite');
    return NativeDatabase(File(dbPath));
  }

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
    int max = 99999;
    for (final r in prodRecipes) {
      if (r.quantity <= 0) continue;
      final ing = await (select(ingredients)..where((i) => i.id.equals(r.ingredientId))).getSingleOrNull();
      if (ing == null) continue;
      final fromThis = (ing.stock / r.quantity).floor();
      if (fromThis < max) max = fromThis;
    }
    return max == 99999 ? -1 : max;
  }

  Future<int> createRecipe(RecipesCompanion data) => into(recipes).insert(data);

  Future<bool> updateRecipe(Recipe recipe) => update(recipes).replace(recipe);

  Future<int> deleteRecipe(int id) =>
      (delete(recipes)..where((r) => r.id.equals(id))).go();

  Future<void> deleteRecipesForProduct(int productId) =>
      (delete(recipes)..where((r) => r.productId.equals(productId))).go();

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<List<Order>> getOrdersForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(orders)
          ..where((o) =>
              o.createdAt.isBiggerOrEqualValue(start) &
              o.createdAt.isSmallerThanValue(end))
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  Future<List<Order>> getOrdersInRange(DateTime from, DateTime to) {
    return (select(orders)
          ..where((o) =>
              o.createdAt.isBiggerOrEqualValue(from) &
              o.createdAt.isSmallerOrEqualValue(to))
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  Future<List<Map<String, dynamic>>> getHourlySales(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final dayOrders = await (select(orders)
          ..where((o) =>
              o.createdAt.isBiggerOrEqualValue(start) &
              o.createdAt.isSmallerThanValue(end)))
        .get();

    final Map<int, double> hourlyRevenue = {};
    final Map<int, int> hourlyCount = {};
    for (int i = 0; i < 24; i++) {
      hourlyRevenue[i] = 0.0;
      hourlyCount[i] = 0;
    }

    for (final o in dayOrders) {
      final h = o.createdAt.hour;
      hourlyRevenue[h] = (hourlyRevenue[h] ?? 0.0) + o.total;
      hourlyCount[h] = (hourlyCount[h] ?? 0) + 1;
    }

    return List.generate(24, (h) => {
      'hour': h,
      'revenue': hourlyRevenue[h],
      'orders': hourlyCount[h],
    });
  }

  Future<List<Map<String, dynamic>>> getEmployeeSalesSummary(DateTime from, DateTime to) async {
    final rangeOrders = await (select(orders)
          ..where((o) =>
              o.createdAt.isBiggerOrEqualValue(from) &
              o.createdAt.isSmallerOrEqualValue(to)))
        .get();

    final allUsers = await getAllUsers();
    final userMap = {for (final u in allUsers) u.id: u.name};

    final Map<int, double> rev = {};
    final Map<int, int> count = {};

    for (final o in rangeOrders) {
      rev[o.userId] = (rev[o.userId] ?? 0.0) + o.total;
      count[o.userId] = (count[o.userId] ?? 0) + 1;
    }

    final result = <Map<String, dynamic>>[];
    for (final userId in rev.keys) {
      final c = count[userId]!;
      result.add({
        'userId': userId,
        'userName': userMap[userId] ?? 'Unknown',
        'orders': c,
        'revenue': rev[userId],
        'avgOrderValue': c > 0 ? (rev[userId]! / c) : 0.0,
      });
    }

    result.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    return result;
  }

  Future<List<OrderItem>> getOrderItems(int orderId) =>
      (select(orderItems)..where((i) => i.orderId.equals(orderId))).get();

  Future<int> createOrder(OrdersCompanion data) => into(orders).insert(data);

  Future<int> createOrderItem(OrderItemsCompanion data) => into(orderItems).insert(data);

  // Full order creation with stock deduction in a transaction
  Future<Order> placeOrder({
    required int userId,
    required List<Map<String, dynamic>> cartItems, // {product, quantity, discount}
    required double orderDiscount,
    required double paid,
    required String paymentMethod,
  }) async {
    return await transaction(() async {
      double subTotal = 0;
      final itemsData = <Map<String, dynamic>>[];

      for (final item in cartItems) {
        final Product prod = item['product'] as Product;
        final int qty = item['quantity'] as int;
        final double itemDiscount = (item['discount'] as double?) ?? 0;

        final double unitPrice = _discountedPrice(prod);
        final double lineTotal = unitPrice * qty - itemDiscount;
        subTotal += lineTotal;

        itemsData.add({
          'product': prod,
          'qty': qty,
          'unitPrice': unitPrice,
          'lineTotal': lineTotal,
          'itemDiscount': itemDiscount,
        });
      }

      final double total = (subTotal - orderDiscount).clamp(0.0, double.infinity);
      final double actualPaid = paid.clamp(0.0, total);
      final double due = (total - actualPaid).clamp(0.0, double.infinity);

      // Insert order
      final orderId = await createOrder(OrdersCompanion.insert(
        userId: userId,
        subTotal: Value(subTotal),
        discount: Value(orderDiscount),
        total: Value(total),
        paid: Value(actualPaid),
        due: Value(due),
        status: Value(due <= 0 ? 1 : 0),
        paymentMethod: Value(paymentMethod),
      ));

      // Insert order items + deduct product stock + deduct ingredients
      for (final item in itemsData) {
        final Product prod = item['product'] as Product;
        final int qty = item['qty'] as int;
        final double unitPrice = item['unitPrice'] as double;
        final double lineTotal = item['lineTotal'] as double;

        final cost = prod.useRecipeCost ? prod.recipeCalculatedCost : prod.purchasePrice;
        final netProfit = (unitPrice - cost) * qty;

        await createOrderItem(OrderItemsCompanion.insert(
          orderId: orderId,
          productId: prod.id,
          productName: prod.name,
          price: unitPrice,
          purchasePrice: Value(cost),
          quantity: qty,
          discount: Value(item['itemDiscount'] as double),
          subTotal: unitPrice * qty,
          total: lineTotal,
          netProfit: Value(netProfit),
        ));

        // Deduct product quantity
        await customUpdate(
          'UPDATE products SET quantity = MAX(0, quantity - ?) WHERE id = ?',
          variables: [Variable.withInt(qty), Variable.withInt(prod.id)],
          updates: {products},
        );

        // Deduct ingredients based on recipe
        final prodRecipes = await getRecipesForProduct(prod.id);
        for (final recipe in prodRecipes) {
          final needed = recipe.quantity * qty;
          await adjustIngredientStock(recipe.ingredientId, -needed);
          await into(inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
            ingredientId: recipe.ingredientId,
            type: 'consume',
            quantity: needed,
            referenceType: const Value('order'),
            referenceId: Value(orderId),
            userId: Value(userId),
            note: Value('Sipariş #$orderId için düşüldü'),
          ));
        }
      }

      // Keep the open shift's live totals in sync so reports don't have to
      // wait until shift close to show today's sales.
      final openShift = await getOpenShift();
      if (openShift != null) {
        await _adjustShiftTotals(openShift.id,
            orderDelta: 1, revenue: total, paymentMethod: paymentMethod);
      }

      await _logAction(userId, 'sale', 'Sipariş #$orderId tamamlandı. Toplam: $total');

      return (select(orders)..where((o) => o.id.equals(orderId))).getSingle();
    });
  }

  // Cancel/return an order. When [restoreStock] is true, the sold products
  // and their recipe ingredients are added back to stock; otherwise the
  // order is just marked returned and stock is left as-is (default).
  Future<void> cancelOrder(int orderId, int userId, {required bool restoreStock}) async {
    await transaction(() async {
      final order = await (select(orders)..where((o) => o.id.equals(orderId))).getSingle();
      if (order.isReturned) throw Exception('Bu sipariş zaten iptal edilmiş.');

      await (update(orders)..where((o) => o.id.equals(orderId))).write(
        const OrdersCompanion(isReturned: Value(true), status: Value(0)),
      );

      if (restoreStock) {
        final items = await getOrderItems(orderId);
        for (final item in items) {
          await customUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            variables: [Variable.withInt(item.quantity), Variable.withInt(item.productId)],
            updates: {products},
          );

          final prodRecipes = await getRecipesForProduct(item.productId);
          for (final recipe in prodRecipes) {
            final restored = recipe.quantity * item.quantity;
            await adjustIngredientStock(recipe.ingredientId, restored);
            await into(inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
              ingredientId: recipe.ingredientId,
              type: 'restore',
              quantity: restored,
              referenceType: const Value('order'),
              referenceId: Value(orderId),
              userId: Value(userId),
              note: Value('Sipariş #$orderId iptali için stoğa iade edildi'),
            ));
          }
        }
      }

      // The order may belong to a shift that has since closed (e.g. return
      // processed the next day) — find whichever shift was open at the
      // time of sale, not just the currently open one.
      final saleShift = await _shiftContaining(order.createdAt);
      if (saleShift != null) {
        await _adjustShiftTotals(saleShift.id,
            orderDelta: -1, revenue: -order.total, paymentMethod: order.paymentMethod);
      }

      await _logAction(userId, 'cancel',
          'Sipariş #$orderId iptal edildi${restoreStock ? ' (stok iade edildi)' : ''}');
    });
  }

  Future<Shift?> _shiftContaining(DateTime at) {
    return (select(shifts)
          ..where((s) =>
              s.openedAt.isSmallerOrEqualValue(at) &
              (s.closedAt.isNull() | s.closedAt.isBiggerOrEqualValue(at)))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Live-updates a shift's order/revenue counters as sales happen, so the
  /// shift report doesn't sit at 0 until close. [closeShift] recomputes
  /// these from scratch anyway, so this is just a running preview.
  Future<void> _adjustShiftTotals(
    int shiftId, {
    required int orderDelta,
    required double revenue,
    required String paymentMethod,
  }) async {
    final isCash = paymentMethod == 'cash';
    await customUpdate(
      'UPDATE shifts SET '
      'order_count = MAX(0, order_count + ?), '
      'total_revenue = MAX(0, total_revenue + ?), '
      'total_cash = MAX(0, total_cash + ?), '
      'total_card = MAX(0, total_card + ?) '
      'WHERE id = ?',
      variables: [
        Variable.withInt(orderDelta),
        Variable.withReal(revenue),
        Variable.withReal(isCash ? revenue : 0),
        Variable.withReal(isCash ? 0 : revenue),
        Variable.withInt(shiftId),
      ],
      updates: {shifts},
    );
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyStats(DateTime day) async {
    final dayOrders = await getOrdersForDay(day);
    final completedOrders = dayOrders.where((o) => !o.isReturned).toList();

    double totalRevenue = 0;
    double totalCost = 0;
    double totalDiscount = 0;

    for (final order in completedOrders) {
      totalRevenue += order.total;
      totalDiscount += order.discount;
      final items = await getOrderItems(order.id);
      for (final item in items) {
        totalCost += item.purchasePrice * item.quantity;
      }
    }

    return {
      'orderCount': completedOrders.length,
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalRevenue - totalCost,
      'discount': totalDiscount,
    };
  }

  // ── Shifts ────────────────────────────────────────────────────────────────

  Future<Shift?> getOpenShift() =>
      (select(shifts)..where((s) => s.isOpen.equals(true))..limit(1)).getSingleOrNull();

  Future<Shift> openShift(int userId, double openingCash) async {
    final id = await into(shifts).insert(ShiftsCompanion.insert(
      userId: userId,
      openingCash: Value(openingCash),
    ));
    await _logAction(userId, 'shift_open', 'Vardiya #$id açıldı. Açılış nakit: $openingCash');
    return (select(shifts)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<Shift> closeShift(int shiftId, int userId, double closingCash) async {
    // Calculate totals from orders placed after shift opened
    final shift = await (select(shifts)..where((s) => s.id.equals(shiftId))).getSingle();
    final shiftOrders = await (select(orders)
          ..where((o) =>
              o.createdAt.isBiggerOrEqualValue(shift.openedAt) &
              o.isReturned.equals(false)))
        .get();

    double totalRevenue = 0;
    double totalCash = 0;
    double totalCard = 0;
    for (final o in shiftOrders) {
      totalRevenue += o.total;
      if (o.paymentMethod == 'cash') {
        totalCash += o.total;
      } else {
        totalCard += o.total;
      }
    }

    await (update(shifts)..where((s) => s.id.equals(shiftId))).write(
      ShiftsCompanion(
        closedAt: Value(DateTime.now()),
        closingCash: Value(closingCash),
        orderCount: Value(shiftOrders.length),
        totalRevenue: Value(totalRevenue),
        totalCash: Value(totalCash),
        totalCard: Value(totalCard),
        isOpen: const Value(false),
      ),
    );
    await _logAction(userId, 'shift_close', 'Vardiya #$shiftId kapatıldı. Toplam: $totalRevenue');
    return (select(shifts)..where((s) => s.id.equals(shiftId))).getSingle();
  }

  Future<List<Shift>> getRecentShifts({int limit = 10}) =>
      (select(shifts)
            ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
            ..limit(limit))
          .get();

  Future<List<Map<String, dynamic>>> getShiftsWithUser({int limit = 50}) async {
    final allShifts = await (select(shifts)
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(limit))
        .get();
    final allUsers = await select(users).get();
    final userMap = {for (final u in allUsers) u.id: u.name};
    return allShifts.map((s) => {
      'shift': s,
      'userName': userMap[s.userId] ?? '—',
    }).toList();
  }

  Future<List<InventoryTransaction>> getRecentTransactions({int limit = 50}) =>
      (select(inventoryTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  // ── Stock Movements (Feature 1) ───────────────────────────────────────────

  /// Stok girişi: malzemeye miktar ekler, transactions'a kaydeder
  Future<void> addStockReceipt({
    required int ingredientId,
    required double qty,
    required double unitCost,
    required int userId,
    String? note,
  }) async {
    await transaction(() async {
      await adjustIngredientStock(ingredientId, qty);
      await into(inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          ingredientId: ingredientId,
          type: 'purchase',
          quantity: qty,
          unitCost: Value(unitCost),
          referenceType: const Value('manual'),
          userId: Value(userId),
          note: Value(note ?? 'Stok girişi'),
        ),
      );
      final ing = await (select(ingredients)..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
      await _logAction(userId, 'stock_adjust',
          'Stok girişi: ${ing?.name ?? ingredientId} — +$qty ${ing?.unit ?? ''}');
    });
  }

  /// Stok silme/zarar: malzemeden miktar düşer, transactions'a kaydeder
  Future<void> addStockWriteOff({
    required int ingredientId,
    required double qty,
    required String reason,
    required int userId,
  }) async {
    await transaction(() async {
      await adjustIngredientStock(ingredientId, -qty);
      await into(inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          ingredientId: ingredientId,
          type: 'manual_adjust',
          quantity: qty,
          referenceType: const Value('manual'),
          userId: Value(userId),
          note: Value(reason),
        ),
      );
      final ing = await (select(ingredients)..where((i) => i.id.equals(ingredientId))).getSingleOrNull();
      await _logAction(userId, 'stock_adjust',
          'Stok silme: ${ing?.name ?? ingredientId} — -$qty ${ing?.unit ?? ''} (Sebep: $reason)');
    });
  }

  /// Belirli bir malzemenin hareket geçmişi
  Future<List<InventoryTransaction>> getIngredientTransactions(
    int ingredientId, {
    DateTime? from,
    DateTime? to,
  }) {
    final q = select(inventoryTransactions)
      ..where((t) => t.ingredientId.equals(ingredientId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (from != null) q.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    if (to != null) q.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    return q.get();
  }

  /// Tüm stok hareketleri (filtreli)
  Future<List<InventoryTransaction>> getAllTransactions({
    int limit = 100,
    DateTime? from,
    DateTime? to,
  }) {
    final q = select(inventoryTransactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (from != null) q.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    if (to != null) q.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    return q.get();
  }

  // ── Action Logs with User (Feature 4) ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getActionLogsWithUser({
    int? userId,
    String? actionType,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    final allLogs = await (select(actionLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();

    final allUsers = await getAllUsers();
    final userMap = {for (final u in allUsers) u.id: u.name};

    return allLogs
        .where((l) {
          if (userId != null && l.userId != userId) return false;
          if (actionType != null && actionType.isNotEmpty && l.action != actionType) return false;
          if (from != null && l.createdAt.isBefore(from)) return false;
          if (to != null && l.createdAt.isAfter(to)) return false;
          return true;
        })
        .map((l) => {
              'log': l,
              'userName': userMap[l.userId] ?? 'System',
            })
        .toList();
  }

  // ── Expiry (Feature 5) ────────────────────────────────────────────────────

  /// Son kullanma tarihi yaklaşan ürünler (varsayılan 7 gün içinde)
  Future<List<Product>> getExpiringProducts({int daysAhead = 7}) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: daysAhead));
    final all = await getAllProducts();
    return all.where((p) {
      if (p.expireDate == null) return false;
      return p.expireDate!.isAfter(now) && p.expireDate!.isBefore(deadline);
    }).toList();
  }

  /// Son kullanma tarihi geçmiş ürünler
  Future<List<Product>> getExpiredProducts() async {
    final now = DateTime.now();
    final all = await getAllProducts();
    return all.where((p) {
      if (p.expireDate == null) return false;
      return p.expireDate!.isBefore(now);
    }).toList();
  }

  // ── Stock Report (Feature 2) ───────────────────────────────────────────────

  /// Kritik düşük stok malzemeleri (minStock > 0 ve stock <= minStock)
  Future<List<Ingredient>> getCriticalStockIngredients() async {
    final all = await getAllIngredients();
    return all.where((i) => i.minStock > 0 && i.stock <= i.minStock).toList();
  }

  /// Genel stok özeti dashboard kartları için
  Future<Map<String, dynamic>> getStockSummary() async {
    final allProducts = await getAllProducts();
    final allIngredients = await getAllIngredients();
    final now = DateTime.now();
    final in7Days = now.add(const Duration(days: 7));

    int expiringSoon = 0;
    int expired = 0;
    int zeroStock = 0;
    double totalProductValue = 0;

    for (final p in allProducts) {
      totalProductValue += p.price * p.quantity;
      if (p.quantity == 0) zeroStock++;
      if (p.expireDate != null) {
        if (p.expireDate!.isBefore(now)) {
          expired++;
        } else if (p.expireDate!.isBefore(in7Days)) {
          expiringSoon++;
        }
      }
    }

    int criticalIngredients = 0;
    double totalIngredientValue = 0;
    for (final i in allIngredients) {
      totalIngredientValue += i.cost * i.stock;
      if (i.minStock > 0 && i.stock <= i.minStock) criticalIngredients++;
    }

    return {
      'productCount': allProducts.length,
      'ingredientCount': allIngredients.length,
      'expiringSoon': expiringSoon,
      'expired': expired,
      'zeroStock': zeroStock,
      'criticalIngredients': criticalIngredients,
      'totalProductValue': totalProductValue,
      'totalIngredientValue': totalIngredientValue,
    };
  }

  // ── Logs ──────────────────────────────────────────────────────────────────

  Future<void> _logAction(int userId, String action, String description) async {
    await into(actionLogs).insert(ActionLogsCompanion.insert(
      userId: Value(userId),
      action: action,
      description: description,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _discountedPrice(Product p) {
    if (p.discountType == 'fixed') return (p.price - p.discount).clamp(0, double.infinity);
    if (p.discountType == 'percentage') {
      return (p.price - p.price * p.discount / 100).clamp(0, double.infinity);
    }
    return p.price;
  }

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
