import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kassa_programma/features/reports/widgets/order_detail_dialog.dart';
import '../../../controllers/reports_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

// ── Tab button ─────────────────────────────────────────────────────────────────

class RepTabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final List<List<dynamic>>? icon;

  const RepTabButton({
    super.key,
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.icon,
  });

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
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isActive
                      ? Colors.white
                      : (isDark ? AppColors.textGrey : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Big stat card ──────────────────────────────────────────────────────────────

class RepBigStatCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const RepBigStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

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
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textGrey
                            : const Color(0xFF64748B))),
              ),
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

// ── Product stat table ─────────────────────────────────────────────────────────

class RepProductTable extends StatelessWidget {
  final List<ProductStat> stats;
  const RepProductTable({super.key, required this.stats});

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
                Expanded(flex: 3, child: _th('prod_name'.tr)),
                Expanded(child: _th('prod_qty'.tr, center: true)),
                Expanded(child: _th('rep_revenue'.tr, right: true)),
                Expanded(child: _th('rep_profit'.tr, right: true)),
                Expanded(child: _th('rep_margin'.tr, right: true)),
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

  Widget _th(String t, {bool center = false, bool right = false}) => Text(t,
      textAlign: center
          ? TextAlign.center
          : right
              ? TextAlign.right
              : TextAlign.left,
      style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textGrey));
}

// ── Employee stat table ────────────────────────────────────────────────────────

class RepEmployeeTable extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const RepEmployeeTable({super.key, required this.stats});

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
                Expanded(flex: 2, child: _th('emp_name'.tr)),
                Expanded(child: _th('rep_orders'.tr, center: true)),
                Expanded(child: _th('rep_revenue'.tr, right: true)),
                Expanded(child: _th('rep_avg_basket'.tr, right: true)),
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

  Widget _th(String t, {bool center = false, bool right = false}) => Text(t,
      textAlign: center
          ? TextAlign.center
          : right
              ? TextAlign.right
              : TextAlign.left,
      style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textGrey));
}

// ── Hourly sales chart ─────────────────────────────────────────────────────────

class HourlySalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;
  const HourlySalesChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
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
}

// ── Orders tab ─────────────────────────────────────────────────────────────────

class RepOrdersTab extends StatelessWidget {
  final ReportsController ctrl;
  final bool isDark;
  const RepOrdersTab({super.key, required this.ctrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              final statusColor = isReturned
                  ? AppColors.red
                  : o.status == 1
                      ? AppColors.green
                      : AppColors.orange;
              final statusLabel = isReturned
                  ? 'order_status_returned'.tr
                  : o.status == 1
                      ? 'order_status_paid'.tr
                      : 'order_status_debt'.tr;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showOrderDetail(context, o, userName),
                  hoverColor:
                      isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(children: [
                      SizedBox(
                          width: colWidths[0],
                          child: Text('#${o.id}',
                              style: const TextStyle(
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
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
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
                                        color: subColor.withAlpha(100))),
                          )),
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
}

// ── Shifts table ───────────────────────────────────────────────────────────────

class RepShiftsTable extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  final int? selectedShiftId;
  final Color borderColor;
  final bool isDark;
  final void Function(Shift?, String) onSelect;

  const RepShiftsTable({
    super.key,
    required this.shifts,
    required this.selectedShiftId,
    required this.borderColor,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurface : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const SizedBox(
                width: 36,
                child: Text('#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textGrey))),
            Expanded(flex: 2, child: _th('emp_name'.tr)),
            Expanded(flex: 2, child: _th('shift_opened_at'.tr)),
            Expanded(flex: 2, child: _th('shift_close'.tr)),
            Expanded(child: _th('shift_hours'.tr, center: true)),
            Expanded(child: _th('rep_orders'.tr, center: true)),
            Expanded(flex: 2, child: _th('rep_revenue'.tr, right: true)),
            Expanded(child: _th('shift_status'.tr, center: true)),
          ]),
        ),
        Divider(color: borderColor, height: 1),
        // Rows
        ...shifts.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final shift = row['shift'] as Shift;
          final userName = row['userName'] as String;
          final isOpen = shift.closedAt == null;
          final isLast = i == shifts.length - 1;
          final isSelected = selectedShiftId == shift.id;
          final duration =
              (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
          final h = duration.inHours;
          final m = duration.inMinutes.remainder(60);

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSelect(
                  isSelected ? null : shift, isSelected ? '' : userName),
              child: Column(children: [
                Container(
                  color: isSelected
                      ? AppColors.primary2.withAlpha(isDark ? 25 : 12)
                      : isOpen
                          ? AppColors.green.withAlpha(isDark ? 15 : 8)
                          : Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    SizedBox(
                      width: 36,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary2
                                  : AppColors.textGrey)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary2.withAlpha(isDark ? 40 : 20),
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
                                      : const Color(0xFF0F172A))),
                        ),
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmt(shift.openedAt),
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text('${shift.openingCash.toStringAsFixed(0)} TMT',
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: isOpen
                          ? const Text('—',
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.textGrey))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fmt(shift.closedAt!),
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(
                                    '${(shift.closingCash ?? 0).toStringAsFixed(0)} TMT',
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 11,
                                        color: AppColors.textGrey)),
                              ],
                            ),
                    ),
                    Expanded(
                      child: Text('${h}s ${m}d',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  h >= 8 ? AppColors.red : AppColors.textGrey)),
                    ),
                    Expanded(
                      child: Text('${shift.orderCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary2)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(formatCurrency(shift.totalRevenue),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green)),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.green.withAlpha(isDark ? 40 : 20)
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
                            isOpen ? 'shift_open'.tr : 'shift_closed'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  isOpen ? AppColors.green : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                if (!isLast) Divider(color: borderColor, height: 1),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _th(String t, {bool center = false, bool right = false}) => Text(t,
      textAlign: center
          ? TextAlign.center
          : right
              ? TextAlign.right
              : TextAlign.left,
      style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textGrey));

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }
}
