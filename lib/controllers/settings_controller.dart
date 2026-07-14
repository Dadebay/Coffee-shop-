import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// General app-wide behavior toggles that don't belong to a single feature
/// controller (theme, locale, printer already have their own).
class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  static const _keyRestoreStockOnReturn = 'restore_stock_on_return';

  /// Whether returning/cancelling an order should add the sold products
  /// and their recipe ingredients back to stock. Off by default — most
  /// shops treat a return as a loss to write off manually, not an
  /// automatic restock.
  final RxBool restoreStockOnReturn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    restoreStockOnReturn.value = p.getBool(_keyRestoreStockOnReturn) ?? false;
  }

  Future<void> setRestoreStockOnReturn(bool v) async {
    restoreStockOnReturn.value = v;
    (await SharedPreferences.getInstance()).setBool(_keyRestoreStockOnReturn, v);
  }
}
