import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ingredients_controller.dart';
import '../core/constants/color_constants.dart';
import '../data/database/app_database.dart';

class StockController extends GetxController {
  static StockController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  // ── Observable state ──────────────────────────────────────────────────────
  final RxList<Ingredient> ingredients = <Ingredient>[].obs;
  final Rx<Ingredient?> selectedIngredient = Rx<Ingredient?>(null);
  final RxList<InventoryTransaction> transactions = <InventoryTransaction>[].obs;
  final RxBool loading = false.obs;
  final RxBool txLoading = false.obs;

  // Filter
  final RxString filterPeriod = 'all'.obs; // all | today | week

  @override
  void onInit() {
    super.onInit();
    loadIngredients();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> loadIngredients() async {
    loading.value = true;
    ingredients.value = await _db.getAllIngredients();
    loading.value = false;

    // If there's a selected ingredient, refresh its transactions
    if (selectedIngredient.value != null) {
      final updated = ingredients.firstWhereOrNull(
        (i) => i.id == selectedIngredient.value!.id,
      );
      if (updated != null) {
        await selectIngredient(updated);
      }
    }
  }

  Future<void> selectIngredient(Ingredient ing) async {
    selectedIngredient.value = ing;
    await loadTransactions(ing.id);
  }

  Future<void> loadTransactions(int ingredientId) async {
    txLoading.value = true;
    final (from, to) = _periodRange();
    transactions.value = await _db.getIngredientTransactions(
      ingredientId,
      from: from,
      to: to,
    );
    txLoading.value = false;
  }

  // ── Stock actions ──────────────────────────────────────────────────────────

  Future<bool> addReceipt({
    required int ingredientId,
    required double qty,
    required double unitCost,
    String? note,
  }) async {
    try {
      final userId = AuthController.to.currentUser.value?.id ?? 0;
      await _db.addStockReceipt(
        ingredientId: ingredientId,
        qty: qty,
        unitCost: unitCost,
        userId: userId,
        note: note,
      );
      await loadIngredients();
      if (Get.isRegistered<IngredientsController>()) {
        await IngredientsController.to.loadAll();
      }
      Get.snackbar(
        'gen_success'.tr,
        'stock_receipt_added'.tr,
        backgroundColor: AppColors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'gen_error'.tr,
        e.toString(),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> addWriteOff({
    required int ingredientId,
    required double qty,
    required String reason,
  }) async {
    try {
      final userId = AuthController.to.currentUser.value?.id ?? 0;
      await _db.addStockWriteOff(
        ingredientId: ingredientId,
        qty: qty,
        reason: reason,
        userId: userId,
      );
      await loadIngredients();
      if (Get.isRegistered<IngredientsController>()) {
        await IngredientsController.to.loadAll();
      }
      Get.snackbar(
        'gen_success'.tr,
        'stock_writeoff_done'.tr,
        backgroundColor: AppColors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'gen_error'.tr,
        e.toString(),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ── Period filter ─────────────────────────────────────────────────────────

  void setPeriod(String period) {
    filterPeriod.value = period;
    if (selectedIngredient.value != null) {
      loadTransactions(selectedIngredient.value!.id);
    }
  }

  (DateTime?, DateTime?) _periodRange() {
    final now = DateTime.now();
    return switch (filterPeriod.value) {
      'today' => (DateTime(now.year, now.month, now.day), null),
      'week' => (now.subtract(const Duration(days: 7)), null),
      _ => (null, null),
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String typeLabel(String type) {
    return switch (type) {
      'purchase' => 'stock_receipt'.tr,
      'manual_adjust' => 'stock_writeoff'.tr,
      'consume' => 'stock_consume'.tr,
      'restore' => 'stock_restore'.tr,
      _ => type,
    };
  }

  bool isPositiveType(String type) => type == 'purchase' || type == 'restore';
}
