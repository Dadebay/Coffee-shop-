import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('rep_title'.tr),
        actions: [
          Obx(() => TextButton.icon(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  color: AppColors.primary2,
                  size: 18,
                ),
                label: Text(
                  '${formatDate(ctrl.from.value)} – ${formatDate(ctrl.to.value)}',
                  style: const TextStyle(
                      fontFamily: 'Gilroy', color: AppColors.primary2, fontSize: 13),
                ),
                onPressed: () => _pickRange(context, ctrl),
              )),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() => ctrl.loading.value
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigStatCard(
                          icon: HugeIcons.strokeRoundedMoney02,
                          label: 'rep_revenue'.tr,
                          value: formatCurrency(ctrl.revenue.value),
                          color: AppColors.green,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigStatCard(
                          icon: HugeIcons.strokeRoundedShoppingBag01,
                          label: 'rep_cost'.tr,
                          value: formatCurrency(ctrl.cost.value),
                          color: AppColors.orange,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('rep_top_products'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  ctrl.productStats.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text('pos_no_products'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy', color: AppColors.textGrey)),
                          ),
                        )
                      : _ProductTable(stats: ctrl.productStats),
                ],
              ),
            )),
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
                  primary: AppColors.primary2,
                  surface: AppColors.bgSurface,
                )
              : ColorScheme.light(
                  primary: AppColors.primary2,
                  surface: Colors.white,
                ),
        ),
        child: child!,
      ),
    );
    if (range != null) ctrl.setRange(range.start, range.end);
  }
}

class _BigStatCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _BigStatCard({
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
            color: Colors.black.withAlpha(isDark ? 0 : 6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 35 : 25),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Accent bar
          Container(
            height: 3,
            width: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          // Value
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
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
    final cardColor   = isDark ? AppColors.bgCard   : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE0E0E6);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSurface : const Color(0xffF5F5F7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('prod_name'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textGrey))),
                Expanded(child: Text('prod_qty'.tr, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textGrey))),
                Expanded(child: Text('rep_revenue'.tr, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textGrey))),
                Expanded(child: Text('rep_profit'.tr, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textGrey))),
                Expanded(child: Text('rep_margin'.tr, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textGrey))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(s.name, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(child: Text('${s.qty}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13))),
                      Expanded(child: Text(formatCurrency(s.revenue), textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: AppColors.green))),
                      Expanded(child: Text(formatCurrency(s.profit), textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: s.profit >= 0 ? AppColors.green : AppColors.red))),
                      Expanded(child: Text('%${s.margin.toStringAsFixed(1)}', textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: AppColors.purple))),
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
