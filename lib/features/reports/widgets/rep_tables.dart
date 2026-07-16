import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

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

