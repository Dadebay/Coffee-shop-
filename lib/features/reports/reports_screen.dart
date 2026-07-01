import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>>? _shifts;
  bool _shiftsLoading = false;

  Future<void> _loadShifts() async {
    if (_shifts != null) return;
    setState(() => _shiftsLoading = true);
    final result = await ShiftController.to.getShiftsWithUser();
    if (mounted)
      setState(() {
        _shifts = result;
        _shiftsLoading = false;
      });
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
            if (ctrl.activeTab.value == 'shifts')
              return const SizedBox.shrink();
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
            if (ctrl.activeTab.value == 'shifts')
              return const SizedBox.shrink();
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
                  ? _buildShiftsTab(isDark)
                  : tab == 'orders'
                      ? (ctrl.loading.value
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary2))
                          : _buildOrdersTab(ctrl, isDark))
                      : (ctrl.loading.value
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary2))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: tab == 'general'
                                  ? _buildGeneralTab(ctrl, context, isDark)
                                  : _buildEmployeesTab(ctrl, context, isDark),
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
              _TabButton(
                title: 'rep_general'.tr,
                isActive: ctrl.activeTab.value == 'general',
                onTap: () => ctrl.setTab('general'),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _TabButton(
                title: 'rep_employees'.tr,
                isActive: ctrl.activeTab.value == 'employees',
                onTap: () => ctrl.setTab('employees'),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _TabButton(
                title: 'rep_shifts'.tr,
                isActive: ctrl.activeTab.value == 'shifts',
                onTap: () {
                  ctrl.setTab('shifts');
                  _loadShifts();
                },
                isDark: isDark,
                icon: HugeIcons.strokeRoundedClock01,
              ),
              const SizedBox(width: 12),
              _TabButton(
                title: 'rep_orders_tab'.tr,
                isActive: ctrl.activeTab.value == 'orders',
                onTap: () => ctrl.setTab('orders'),
                isDark: isDark,
                icon: HugeIcons.strokeRoundedShoppingCart01,
              ),
            ],
          )),
    );
  }

  Widget _buildOrdersTab(ReportsController ctrl, bool isDark) {
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final headerBg = isDark ? AppColors.bgSurface : const Color(0xFFF4F6FB);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final subColor = isDark ? AppColors.textDim : const Color(0xFF94A3B8);

    final orders = ctrl.ordersList;
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              size: 56,
              color: AppColors.textDim),
          const SizedBox(height: 12),
          Text('rep_no_orders_period'.tr,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.textGrey,
                  fontSize: 15)),
        ]),
      );
    }

    const colWidths = [60.0, 160.0, 130.0, 110.0, 100.0, 90.0, 80.0];
    final headers = [
      '#',
      'rep_cashier'.tr,
      'rep_time'.tr,
      'rep_total_col'.tr,
      'rep_payment'.tr,
      'rep_disc_short'.tr,
      'gen_status'.tr,
    ];

    return Column(children: [
      // Header row
      Container(
        color: headerBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
            children: List.generate(
                headers.length,
                (i) => SizedBox(
                      width: colWidths[i],
                      child: Text(headers[i],
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: subColor)),
                    ))),
      ),
      Divider(color: borderColor, height: 1),
      // Rows
      Expanded(
        child: Obx(() {
          final _ = ctrl.usersMap.length;
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: ctrl.ordersList.length,
            separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
            itemBuilder: (_, i) {
              final o = ctrl.ordersList[i];
              final userName = ctrl.usersMap[o.userId] ?? '—';
              final dt = o.createdAt;
              final dateStr =
                  '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
              final timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              final isReturned = o.isReturned;
              final payLabel = o.paymentMethod == 'cash'
                  ? 'pay_method_cash'.tr
                  : o.paymentMethod == 'card'
                      ? 'pay_method_card'.tr
                      : 'pay_method_mixed'.tr;

              Color statusColor = isReturned
                  ? AppColors.red
                  : o.status == 1
                      ? AppColors.green
                      : AppColors.orange;
              String statusLabel = isReturned
                  ? 'order_status_returned'.tr
                  : o.status == 1
                      ? 'order_status_paid'.tr
                      : 'order_status_debt'.tr;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showOrderDetail(o, ctrl, isDark),
                  hoverColor:
                      isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(children: [
                      SizedBox(
                          width: colWidths[0],
                          child: Text('#${o.id}',
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary2))),
                      SizedBox(
                          width: colWidths[1],
                          child: Text(userName,
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor),
                              overflow: TextOverflow.ellipsis)),
                      SizedBox(
                          width: colWidths[2],
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateStr,
                                    style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 12,
                                        color: textColor)),
                                Text(timeStr,
                                    style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 11,
                                        color: subColor)),
                              ])),
                      SizedBox(
                          width: colWidths[3],
                          child: Text(formatCurrency(o.total),
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary2))),
                      SizedBox(
                          width: colWidths[4],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.primary2.withAlpha(20),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(payLabel,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary2)),
                          )),
                      SizedBox(
                          width: colWidths[5],
                          child: o.discount > 0
                              ? Text(formatCurrency(o.discount),
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      color: AppColors.orange))
                              : Text('—',
                                  style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 14,
                                      color: subColor.withAlpha(100)))),
                      SizedBox(
                          width: colWidths[6],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: statusColor.withAlpha(60))),
                            child: Text(statusLabel,
                                style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          )),
                    ]),
                  ),
                ),
              );
            },
          );
        }),
      ),
    ]);
  }

  void _showOrderDetail(Order order, ReportsController ctrl, bool isDark) {
    final db = Get.find<DatabaseController>().db;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    final dt = order.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final cashier = ctrl.usersMap[order.userId] ?? '—';

    Get.dialog(Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
          width: 420,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.primary2.withAlpha(20),
                            borderRadius: BorderRadius.circular(10)),
                        child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedShoppingCart01,
                            size: 18,
                            color: AppColors.primary2)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${'rep_order_detail'.tr}${order.id}',
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor)),
                          Text('$cashier  ·  $dateStr',
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  color: AppColors.textGrey)),
                        ])),
                    GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(Icons.close,
                            color: AppColors.textGrey, size: 20)),
                  ]),
                ),
                Divider(color: borderColor, height: 1),
                // Items via FutureBuilder — no rebuild loop
                FutureBuilder<List<OrderItem>>(
                  future: db.getOrderItems(order.id),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary2)));
                    }
                    final items = snap.data!;
                    if (items.isEmpty) {
                      return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                              child: Text('pos_no_products'.tr,
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: AppColors.textGrey))));
                    }
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: borderColor, height: 1),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: Row(children: [
                                Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(7)),
                                    child: Center(
                                        child: Text(
                                            it.productName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                fontFamily: 'Gilroy',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.primary2)))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(it.productName,
                                        style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor))),
                                Text('×${it.quantity}',
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 12,
                                        color: AppColors.textGrey)),
                                const SizedBox(width: 12),
                                Text(formatCurrency(it.total),
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary2)),
                              ]));
                        },
                      ),
                    );
                  },
                ),
                Divider(color: borderColor, height: 1),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(children: [
                      if (order.discount > 0) ...[
                        Text('${'rep_disc_short'.tr}: ${formatCurrency(order.discount)}',
                            style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                color: AppColors.orange)),
                        const SizedBox(width: 16),
                      ],
                      const Spacer(),
                      Text('${'rep_total_col'.tr}: ',
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: AppColors.textGrey)),
                      Text(formatCurrency(order.total),
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary2)),
                    ])),
              ])),
    ));
  }

  Widget _buildShiftsTab(bool isDark) {
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

    return SingleChildScrollView(
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
            child: Column(
              children: [
                // Header row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.bgSurface : const Color(0xFFF8FAFC),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('emp_name'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          flex: 2,
                          child: Text('shift_opened_at'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          flex: 2,
                          child: Text('shift_close'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          child: Text('shift_hours'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          child: Text('rep_orders'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          flex: 2,
                          child: Text('rep_revenue'.tr,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                      Expanded(
                          child: Text('shift_status'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textGrey))),
                    ],
                  ),
                ),
                Divider(color: borderColor, height: 1),
                ..._shifts!.asMap().entries.map((e) {
                  final i = e.key;
                  final row = e.value;
                  final shift = row['shift'] as Shift;
                  final userName = row['userName'] as String;
                  final isOpen = shift.closedAt == null;
                  final isLast = i == _shifts!.length - 1;
                  final duration = (shift.closedAt ?? DateTime.now())
                      .difference(shift.openedAt);
                  final h = duration.inHours;
                  final m = duration.inMinutes.remainder(60);

                  return Column(
                    children: [
                      Container(
                        color: isOpen
                            ? AppColors.green.withAlpha(isDark ? 15 : 8)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            // Name + avatar
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary2
                                          .withAlpha(isDark ? 40 : 20),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty
                                            ? userName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.primary2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(userName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textWhite
                                              : const Color(0xFF0F172A),
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            // Open time
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_fmtDateTime(shift.openedAt),
                                      style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    '${shift.openingCash.toStringAsFixed(0)} TMT',
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 11,
                                        color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                            // Close time
                            Expanded(
                              flex: 2,
                              child: isOpen
                                  ? const Text('—',
                                      style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          color: AppColors.textGrey))
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_fmtDateTime(shift.closedAt!),
                                            style: const TextStyle(
                                                fontFamily: 'Gilroy',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                          '${(shift.closingCash ?? 0).toStringAsFixed(0)} TMT',
                                          style: const TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 11,
                                              color: AppColors.textGrey),
                                        ),
                                      ],
                                    ),
                            ),
                            // Duration
                            Expanded(
                              child: Text(
                                '${h}s ${m}d',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: h >= 8
                                      ? AppColors.red
                                      : AppColors.textGrey,
                                ),
                              ),
                            ),
                            // Order count
                            Expanded(
                              child: Text(
                                '${shift.orderCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary2),
                              ),
                            ),
                            // Revenue
                            Expanded(
                              flex: 2,
                              child: Text(
                                formatCurrency(shift.totalRevenue),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green),
                              ),
                            ),
                            // Status
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? AppColors.green
                                            .withAlpha(isDark ? 40 : 20)
                                        : AppColors.textGrey
                                            .withAlpha(isDark ? 40 : 15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isOpen
                                          ? AppColors.green.withAlpha(80)
                                          : AppColors.bgBorder,
                                    ),
                                  ),
                                  child: Text(
                                    isOpen
                                        ? 'shift_open'.tr
                                        : 'shift_closed'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isOpen
                                          ? AppColors.green
                                          : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) Divider(color: borderColor, height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  Widget _buildGeneralTab(
      ReportsController ctrl, BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _BigStatCard(
                    icon: HugeIcons.strokeRoundedReceiptText,
                    label: 'rep_orders'.tr,
                    value: '${ctrl.orderCount.value}',
                    color: AppColors.primary2,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _BigStatCard(
                    icon: HugeIcons.strokeRoundedMoney02,
                    label: 'rep_revenue'.tr,
                    value: formatCurrency(ctrl.revenue.value),
                    color: AppColors.green,
                    isDark: isDark)),
            const SizedBox(width: 16),
            Expanded(
                child: _BigStatCard(
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    label: 'rep_cost'.tr,
                    value: formatCurrency(ctrl.cost.value),
                    color: AppColors.orange,
                    isDark: isDark)),
          ],
        ),
        const SizedBox(height: 32),
        _buildHourlySalesChart(ctrl, isDark),
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
                            fontFamily: 'Gilroy', color: AppColors.textGrey))))
            : _ProductTable(stats: ctrl.productStats),
      ],
    );
  }

  Widget _buildHourlySalesChart(ReportsController ctrl, bool isDark) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final data = ctrl.hourlySales;
    if (data.isEmpty) return const SizedBox();

    double maxRev = 0;
    for (var d in data) {
      if ((d['revenue'] as double) > maxRev) maxRev = d['revenue'] as double;
    }
    if (maxRev == 0) maxRev = 100;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('rep_hourly_sales'.tr,
              style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRev * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    formatCurrency(rod.toY),
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy'),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 3 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${value.toInt()}:00',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textGrey
                                    : AppColors.textDim,
                                fontSize: 10,
                                fontFamily: 'Gilroy')),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxRev / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data
                  .map((d) => BarChartGroupData(
                        x: d['hour'] as int,
                        barRods: [
                          BarChartRodData(
                              toY: d['revenue'] as double,
                              color: AppColors.primary2,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)))
                        ],
                      ))
                  .toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab(
      ReportsController ctrl, BuildContext context, bool isDark) {
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
                            fontFamily: 'Gilroy', color: AppColors.textGrey))))
            : _EmployeeTable(stats: ctrl.employeeSales),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context, ReportsController ctrl) async {
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
                  primary: AppColors.primary2, surface: AppColors.bgSurface)
              : const ColorScheme.light(
                  primary: AppColors.primary2, surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (range != null) ctrl.setRange(range.start, range.end);
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final List<List<dynamic>>? icon;

  const _TabButton(
      {required this.title,
      required this.isActive,
      required this.onTap,
      required this.isDark,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary2
              : (isDark ? AppColors.bgCard : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(
                  icon: icon!,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.textGrey),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive
                    ? Colors.white
                    : (isDark ? AppColors.textGrey : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _BigStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Center(child: HugeIcon(icon: icon, color: color, size: 22)),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textGrey
                          : const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 20),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<ProductStat> stats;
  const _ProductTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE2E8F0);
    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isDark ? AppColors.bgSurface : const Color(0xffF8FAFC),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14))),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('prod_name'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('prod_qty'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_revenue'.tr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_profit'.tr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_margin'.tr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          ...stats.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isLast = i == stats.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(s.name,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14))),
                      Expanded(
                          child: Text('${s.qty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy', fontSize: 14))),
                      Expanded(
                          child: Text(formatCurrency(s.revenue),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.green))),
                      Expanded(
                          child: Text(formatCurrency(s.profit),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: s.profit >= 0
                                      ? AppColors.green
                                      : AppColors.red))),
                      Expanded(
                          child: Text('%${s.margin.toStringAsFixed(1)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 14,
                                  color: AppColors.purple))),
                    ],
                  ),
                ),
                if (!isLast) Divider(color: borderColor, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _EmployeeTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE2E8F0);
    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isDark ? AppColors.bgSurface : const Color(0xffF8FAFC),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14))),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('emp_name'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_orders'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_revenue'.tr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
                Expanded(
                    child: Text('rep_avg_basket'.tr,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textGrey))),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          ...stats.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isLast = i == stats.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(s['userName'],
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14))),
                      Expanded(
                          child: Text('${s['orders']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy', fontSize: 14))),
                      Expanded(
                          child: Text(formatCurrency(s['revenue'] as double),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.green))),
                      Expanded(
                          child: Text(
                              formatCurrency(s['avgOrderValue'] as double),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.primary2))),
                    ],
                  ),
                ),
                if (!isLast) Divider(color: borderColor, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}
