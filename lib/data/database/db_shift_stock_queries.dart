part of 'app_database.dart';

/// Shifts, stock movements, action logs, expiry and stock summary.
extension ShiftStockQueries on AppDatabase {
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
  Future<List<Ingredient>> getCriticalStockIngredients() =>
      getLowStockIngredients();

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

}
