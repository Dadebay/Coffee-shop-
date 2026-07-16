import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../../core/utils/pricing.dart';
import '../seeds/owaz_seed.dart';

part 'app_database.g.dart';
part 'db_tables.dart';
part 'db_catalog_queries.dart';
part 'db_order_queries.dart';
part 'db_shift_stock_queries.dart';

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

  // ── Logs ──────────────────────────────────────────────────────────────────

  Future<void> _logAction(int userId, String action, String description) async {
    await into(actionLogs).insert(ActionLogsCompanion.insert(
      userId: Value(userId),
      action: action,
      description: description,
    ));
  }

}
