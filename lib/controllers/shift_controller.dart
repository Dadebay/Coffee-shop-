import 'package:get/get.dart';
import '../data/database/app_database.dart';
import 'auth_controller.dart';
import 'database_controller.dart';

class ShiftController extends GetxController {
  static ShiftController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final Rx<Shift?> activeShift = Rx<Shift?>(null);
  final RxBool loading = false.obs;

  bool get isOpen => activeShift.value != null;

  @override
  void onInit() {
    super.onInit();
    _loadActiveShift();
  }

  Future<void> _loadActiveShift() async {
    activeShift.value = await _db.getOpenShift();
  }

  Future<void> openShift(double openingCash) async {
    final user = AuthController.to.currentUser.value;
    if (user == null) return;
    loading.value = true;
    try {
      final shift = await _db.openShift(user.id, openingCash);
      activeShift.value = shift;
    } finally {
      loading.value = false;
    }
  }

  // Returns the closed shift summary
  Future<Shift> closeShift(double closingCash) async {
    final user = AuthController.to.currentUser.value;
    if (user == null) throw Exception('Kullanıcı bulunamadı');
    final shift = activeShift.value;
    if (shift == null) throw Exception('Açık vardiya yok');
    loading.value = true;
    try {
      final closed = await _db.closeShift(shift.id, user.id, closingCash);
      activeShift.value = null;
      return closed;
    } finally {
      loading.value = false;
    }
  }

  Future<List<Shift>> getRecentShifts() => _db.getRecentShifts();

  Future<List<Map<String, dynamic>>> getShiftsWithUser() => _db.getShiftsWithUser();
}
