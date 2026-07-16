part of 'app_database.dart';

/// Orders: creation, cancellation, per-day/range fetches, sales reports.
extension OrderQueries on AppDatabase {
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

  /// Items for many orders in one query, grouped by orderId.
  Future<Map<int, List<OrderItem>>> getOrderItemsForOrders(
      List<int> orderIds) async {
    if (orderIds.isEmpty) return {};
    final rows = await (select(orderItems)
          ..where((i) => i.orderId.isIn(orderIds)))
        .get();
    final map = <int, List<OrderItem>>{};
    for (final row in rows) {
      map.putIfAbsent(row.orderId, () => []).add(row);
    }
    return map;
  }

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

        final double unitPrice = prod.discountedPrice;
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

}
