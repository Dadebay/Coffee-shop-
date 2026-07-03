import 'package:get/get.dart';
import '../data/database/app_database.dart';
import 'database_controller.dart';

class ActionLogController extends GetxController {
  static ActionLogController get to => Get.find();
  final _db = Get.find<DatabaseController>().db;

  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> logs = <Map<String, dynamic>>[].obs;
  final RxList<User> users = <User>[].obs;

  // Filters
  final RxnInt selectedUserId = RxnInt();
  final RxnString selectedActionType = RxnString();
  final Rx<DateTime> fromDate = DateTime.now().subtract(const Duration(days: 6)).obs;
  final Rx<DateTime> toDate = DateTime.now().obs;

  static const List<String> actionTypes = [
    'sale',
    'cancel',
    'price_change',
    'stock_adjust',
    'shift_close',
    'shift_open',
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      users.value = await _db.getAllUsers();
      await _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _applyFilters() async {
    final start = DateTime(fromDate.value.year, fromDate.value.month, fromDate.value.day);
    final end = DateTime(toDate.value.year, toDate.value.month, toDate.value.day, 23, 59, 59);

    logs.value = await _db.getActionLogsWithUser(
      userId: selectedUserId.value,
      actionType: selectedActionType.value,
      from: start,
      to: end,
      limit: 200,
    );
  }

  void setDateRange(DateTime f, DateTime t) {
    fromDate.value = f;
    toDate.value = t;
    _applyFilters();
  }

  void setUser(int? userId) {
    selectedUserId.value = userId;
    _applyFilters();
  }

  void setActionType(String? type) {
    selectedActionType.value = type;
    _applyFilters();
  }

  void clearFilters() {
    selectedUserId.value = null;
    selectedActionType.value = null;
    fromDate.value = DateTime.now().subtract(const Duration(days: 6));
    toDate.value = DateTime.now();
    _applyFilters();
  }
}
