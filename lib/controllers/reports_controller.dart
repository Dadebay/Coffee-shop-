import 'package:get/get.dart';
import '../data/database/app_database.dart';
import '../features/reports/export_service.dart';
import 'database_controller.dart';

class ProductStat {
  final String name;
  int qty;
  double revenue;
  double cost;

  ProductStat({required this.name, this.qty = 0, this.revenue = 0, this.cost = 0});

  double get profit => revenue - cost;
  double get margin => revenue > 0 ? profit / revenue * 100 : 0;
}

class ReportsController extends GetxController {

  final _db = Get.find<DatabaseController>().db;

  final Rx<DateTime> from = DateTime.now().subtract(const Duration(days: 6)).obs;
  final Rx<DateTime> to = DateTime.now().obs;
  final RxBool loading = false.obs;

  final RxInt orderCount = 0.obs;
  final RxDouble revenue = 0.0.obs;
  final RxDouble cost = 0.0.obs;
  final RxDouble profit = 0.0.obs;
  final RxDouble discount = 0.0.obs;
  final RxDouble margin = 0.0.obs;
  final RxList<ProductStat> productStats = <ProductStat>[].obs;
  
  final RxList<Map<String, dynamic>> hourlySales = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employeeSales = <Map<String, dynamic>>[].obs;
  final RxString activeTab = 'general'.obs; // general | employees | orders | shifts

  // Orders tab
  final RxList<Order> ordersList = <Order>[].obs;
  final RxMap<int, String> usersMap = <int, String>{}.obs; // userId → name


  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setRange(DateTime f, DateTime t) async {
    from.value = f;
    to.value = t;
    await load();
  }

  Future<void> load() async {
    loading.value = true;

    final start = DateTime(from.value.year, from.value.month, from.value.day);
    final end = DateTime(to.value.year, to.value.month, to.value.day, 23, 59, 59);
    final orders = await _db.getOrdersInRange(start, end);
    final completed = orders.where((o) => !o.isReturned).toList();

    double totalRev = 0, totalCost = 0, totalDisc = 0;
    final Map<int, ProductStat> map = {};

    final itemsByOrder =
        await _db.getOrderItemsForOrders(completed.map((o) => o.id).toList());

    for (final order in completed) {
      totalRev += order.total;
      totalDisc += order.discount;
      final items = itemsByOrder[order.id] ?? const [];
      for (final item in items) {
        totalCost += item.purchasePrice * item.quantity;
        map.update(
          item.productId,
          (s) {
            s.qty += item.quantity;
            s.revenue += item.total;
            s.cost += item.purchasePrice * item.quantity;
            return s;
          },
          ifAbsent: () => ProductStat(
            name: item.productName,
            qty: item.quantity,
            revenue: item.total,
            cost: item.purchasePrice * item.quantity,
          ),
        );
      }
    }

    final stats = map.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    orderCount.value = completed.length;
    revenue.value = totalRev;
    cost.value = totalCost;
    profit.value = totalRev - totalCost;
    discount.value = totalDisc;
    margin.value = totalRev > 0 ? (totalRev - totalCost) / totalRev * 100 : 0;
    productStats.value = stats;

    // Load extra stats
    hourlySales.value = await _db.getHourlySales(start);
    employeeSales.value = await _db.getEmployeeSalesSummary(start, end);

    // Orders tab — reuse already-fetched list (includes returned orders)
    ordersList.value = List.from(orders);
    final allUsers = await _db.getAllUsers();
    usersMap.value = {for (final u in allUsers) u.id: u.name};

    loading.value = false;
  }

  void setTab(String tab) {
    activeTab.value = tab;
    loading.value = false;
  }

  /// Returns `true` if the file was saved, `false` if the user cancelled
  /// the save dialog.
  Future<bool> exportOrders() async {
    final start = DateTime(from.value.year, from.value.month, from.value.day);
    final end = DateTime(to.value.year, to.value.month, to.value.day, 23, 59, 59);
    final orders = await _db.getOrdersInRange(start, end);
    return ExportService.exportOrders(
      orders,
      periodFrom: from.value,
      periodTo: to.value,
      usersMap: usersMap,
    );
  }
}
