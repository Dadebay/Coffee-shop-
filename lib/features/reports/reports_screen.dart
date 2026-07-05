import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/reports_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';
import 'widgets/order_detail_dialog.dart';
import 'widgets/rep_widgets.dart';
import 'widgets/shift_detail_panel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>>? _shifts;
  bool _shiftsLoading = false;
  Shift? _selectedShift;
  String _selectedShiftUserName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.find<ReportsController>().activeTab.value == 'shifts') {
        _loadShifts();
      }
    });
  }

  Future<void> _loadShifts() async {
    if (_shifts != null) return;
    setState(() => _shiftsLoading = true);
    final result = await ShiftController.to.getShiftsWithUser();
    if (mounted) {
      setState(() {
        _shifts = result;
        _shiftsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFF5F5F7);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
        title: Text('rep_title'.tr,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy')),
        actions: [
          Obx(() {
            if (ctrl.activeTab.value == 'shifts') return const SizedBox.shrink();
            return TextButton.icon(
              icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  color: AppColors.primary2,
                  size: 18),
              label: Text(
                '${formatDate(ctrl.from.value)} – ${formatDate(ctrl.to.value)}',
                style: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.primary2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              onPressed: () => _pickRange(context, ctrl),
            );
          }),
          Obx(() {
            if (ctrl.activeTab.value == 'shifts') return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await ctrl.exportOrders();
                    Get.snackbar('gen_success'.tr, 'rep_excel_success'.tr,
                        backgroundColor: AppColors.green,
                        colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('gen_error'.tr, '${'rep_excel_fail'.tr}$e',
                        backgroundColor: AppColors.red,
                        colorText: Colors.white);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFile01,
                    color: Colors.white,
                    size: 18),
                label: const Text('Excel',
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final tab = ctrl.activeTab.value;
        return Column(
          children: [
            _buildTabs(ctrl, isDark),
            Expanded(
              child: tab == 'shifts'
                  ? _buildShiftsTab(context, isDark)
                  : (ctrl.loading.value
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary2))
                      : tab == 'orders'
                          ? RepOrdersTab(ctrl: ctrl, isDark: isDark)
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: tab == 'general'
                                  ? _buildGeneralTab(ctrl, isDark)
                                  : _buildEmployeesTab(ctrl, isDark),
                            )),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabs(ReportsController ctrl, bool isDark) {
    return Container(
      color: isDark ? AppColors.bgSurface : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Obx(() => Row(
            children: [
              Flexible(
                child: RepTabButton(
                  title: 'rep_general'.tr,
                  isActive: ctrl.activeTab.value == 'general',
                  onTap: () => ctrl.setTab('general'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RepTabButton(
                  title: 'rep_employees'.tr,
                  isActive: ctrl.activeTab.value == 'employees',
                  onTap: () => ctrl.setTab('employees'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RepTabButton(
                  title: 'rep_shifts'.tr,
                  isActive: ctrl.activeTab.value == 'shifts',
                  onTap: () {
                    ctrl.setTab('shifts');
                    _loadShifts();
                  },
                  isDark: isDark,
                  icon: HugeIcons.strokeRoundedClock01,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RepTabButton(
                  title: 'rep_orders_tab'.tr,
                  isActive: ctrl.activeTab.value == 'orders',
                  onTap: () => ctrl.setTab('orders'),
                  isDark: isDark,
                  icon: HugeIcons.strokeRoundedShoppingCart01,
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildShiftsTab(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    if (_shiftsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary2));
    }
    if (_shifts == null || _shifts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                size: 56,
                color: AppColors.textDim),
            const SizedBox(height: 12),
            Text('rep_no_shifts'.tr,
                style: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: AppColors.textGrey,
                    fontSize: 15)),
          ],
        ),
      );
    }

    final table = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('rep_shifts'.tr,
              style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 0 : 5),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: RepShiftsTable(
              shifts: _shifts!,
              selectedShiftId: _selectedShift?.id,
              borderColor: borderColor,
              isDark: isDark,
              onSelect: (shift, userName) => setState(() {
                _selectedShift = shift;
                _selectedShiftUserName = userName;
              }),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: table),
            if (_selectedShift != null)
              SizedBox(
                width: (constraints.maxWidth * 0.36).clamp(320.0, 520.0),
                child: ShiftDetailPanel(
                  key: ValueKey(_selectedShift!.id),
                  shift: _selectedShift!,
                  userName: _selectedShiftUserName,
                  isDark: isDark,
                  onClose: () => setState(() {
                    _selectedShift = null;
                    _selectedShiftUserName = '';
                  }),
                  onOrderTap: (o) => showOrderDetail(
                    ctx,
                    o,
                    Get.find<ReportsController>().usersMap[o.userId] ?? '—',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralTab(ReportsController ctrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: RepBigStatCard(
                    icon: HugeIcons.strokeRoundedReceiptText,
                    label: 'rep_orders'.tr,
                    value: '${ctrl.orderCount.value}',
                    color: AppColors.primary2,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: RepBigStatCard(
                    icon: HugeIcons.strokeRoundedMoney02,
                    label: 'rep_revenue'.tr,
                    value: formatCurrency(ctrl.revenue.value),
                    color: AppColors.green,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: RepBigStatCard(
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    label: 'rep_cost'.tr,
                    value: formatCurrency(ctrl.cost.value),
                    color: AppColors.orange,
                    isDark: isDark)),
          ],
        ),
        const SizedBox(height: 32),
        HourlySalesChart(data: ctrl.hourlySales, isDark: isDark),
        const SizedBox(height: 32),
        Text('rep_top_products'.tr,
            style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 16),
        ctrl.productStats.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Text('pos_no_products'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.textGrey))))
            : RepProductTable(stats: ctrl.productStats),
      ],
    );
  }

  Widget _buildEmployeesTab(ReportsController ctrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('rep_emp_sales'.tr,
            style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 16),
        ctrl.employeeSales.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Text('pos_no_products'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.textGrey))))
            : RepEmployeeTable(stats: ctrl.employeeSales),
      ],
    );
  }

  Future<void> _pickRange(
      BuildContext context, ReportsController ctrl) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: ctrl.from.value, end: ctrl.to.value),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: AppColors.primary2,
                  surface: AppColors.bgSurface)
              : const ColorScheme.light(
                  primary: AppColors.primary2,
                  surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (range != null) ctrl.setRange(range.start, range.end);
  }
}
