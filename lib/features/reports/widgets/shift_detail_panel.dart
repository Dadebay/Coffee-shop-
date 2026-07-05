import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/database_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

class ShiftDetailPanel extends StatefulWidget {
  final Shift shift;
  final String userName;
  final bool isDark;
  final VoidCallback onClose;
  final void Function(Order) onOrderTap;

  const ShiftDetailPanel({
    super.key,
    required this.shift,
    required this.userName,
    required this.isDark,
    required this.onClose,
    required this.onOrderTap,
  });

  @override
  State<ShiftDetailPanel> createState() => _ShiftDetailPanelState();
}

class _ShiftDetailPanelState extends State<ShiftDetailPanel> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final shift = widget.shift;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final subColor = isDark ? AppColors.textDim : const Color(0xFF94A3B8);
    final isOpen = shift.closedAt == null;
    final duration =
        (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final db = Get.find<DatabaseController>().db;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : Colors.white,
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: AppColors.primary2.withAlpha(20),
                    borderRadius: BorderRadius.circular(9)),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 16,
                    color: AppColors.primary2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Смена #${shift.id}',
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      Text('${widget.userName}  ·  ${_fmt(shift.openedAt)}',
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              color: AppColors.textGrey)),
                    ]),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bgBorder
                          : const Color(0xFFEEF0F6),
                      borderRadius: BorderRadius.circular(7)),
                  child: const Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 13,
                          color: AppColors.textGrey)),
                ),
              ),
            ]),
          ),
          Divider(color: borderColor, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stat cards ──
                  Row(children: [
                    _stat('rep_revenue'.tr, formatCurrency(shift.totalRevenue),
                        AppColors.green, isDark),
                    const SizedBox(width: 8),
                    _stat('pay_method_cash'.tr,
                        formatCurrency(shift.totalCash), AppColors.primary2, isDark),
                    const SizedBox(width: 8),
                    _stat('pay_method_card'.tr,
                        formatCurrency(shift.totalCard), AppColors.purple, isDark),
                    const SizedBox(width: 8),
                    _stat('rep_orders'.tr, '${shift.orderCount}',
                        AppColors.orange, isDark),
                  ]),
                  const SizedBox(height: 10),
                  // ── Info tiles ──
                  Row(children: [
                    Expanded(
                        child: _tile(
                            'shift_opened_at'.tr,
                            _fmt(shift.openedAt),
                            '${shift.openingCash.toStringAsFixed(0)} TMT',
                            borderColor,
                            textColor,
                            subColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: isOpen
                            ? _tile('shift_close'.tr, 'shift_open'.tr, null,
                                borderColor, AppColors.green, AppColors.green)
                            : _tile(
                                'shift_close'.tr,
                                _fmt(shift.closedAt!),
                                '${(shift.closingCash ?? 0).toStringAsFixed(0)} TMT',
                                borderColor,
                                textColor,
                                subColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _tile('shift_hours'.tr, '${h}s ${m}d', null,
                            borderColor, textColor, subColor)),
                  ]),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 10),
                  Text('rep_orders'.tr,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 8),
                  // ── Orders list ──
                  FutureBuilder<List<Order>>(
                    future: db.getOrdersInRange(
                        shift.openedAt, shift.closedAt ?? DateTime.now()),
                    builder: (_, snap) {
                      if (!snap.hasData) {
                        return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary2)));
                      }
                      final ords = snap.data!;
                      if (ords.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                              child: Text('rep_no_orders_period'.tr,
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: AppColors.textGrey))),
                        );
                      }
                      return Column(
                        children: ords.asMap().entries.map((e) {
                          final idx = e.key;
                          final o = e.value;
                          final dt = o.createdAt;
                          final timeStr =
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          final payLabel = o.paymentMethod == 'cash'
                              ? 'pay_method_cash'.tr
                              : o.paymentMethod == 'card'
                                  ? 'pay_method_card'.tr
                                  : 'pay_method_mixed'.tr;
                          final isReturned = o.isReturned;
                          final sColor = isReturned
                              ? AppColors.red
                              : o.status == 1
                                  ? AppColors.green
                                  : AppColors.orange;
                          final sLabel = isReturned
                              ? 'order_status_returned'.tr
                              : o.status == 1
                                  ? 'order_status_paid'.tr
                                  : 'order_status_debt'.tr;

                          return Column(children: [
                            if (idx > 0) Divider(color: borderColor, height: 1),
                            InkWell(
                              onTap: () => widget.onOrderTap(o),
                              hoverColor: isDark
                                  ? AppColors.bgCard
                                  : const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Row(children: [
                                  SizedBox(
                                    width: 26,
                                    child: Text('${idx + 1}',
                                        style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: subColor)),
                                  ),
                                  SizedBox(
                                    width: 42,
                                    child: Text('#${o.id}',
                                        style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary2)),
                                  ),
                                  SizedBox(
                                    width: 42,
                                    child: Text(timeStr,
                                        style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 11,
                                            color: subColor)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color:
                                            AppColors.primary2.withAlpha(15),
                                        borderRadius:
                                            BorderRadius.circular(4)),
                                    child: Text(payLabel,
                                        style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary2)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: sColor.withAlpha(20),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: sColor.withAlpha(60))),
                                    child: Text(sLabel,
                                        style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: sColor)),
                                  ),
                                  const Spacer(),
                                  if (o.discount > 0) ...[
                                    Text('-${formatCurrency(o.discount)}',
                                        style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.orange)),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(formatCurrency(o.total),
                                      style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary2)),
                                ]),
                              ),
                            ),
                          ]);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ──
          Divider(color: borderColor, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              const Spacer(),
              Text('${'rep_total_col'.tr}: ',
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: AppColors.textGrey)),
              Text(formatCurrency(shift.totalRevenue),
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary2)),
            ]),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }

  Widget _stat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 10,
                  color: color.withAlpha(isDark ? 200 : 180))),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ),
    );
  }

  Widget _tile(String label, String value, String? sub, Color borderColor,
      Color textColor, Color subColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 10,
                color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor)),
        if (sub != null)
          Text(sub,
              style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 10,
                  color: AppColors.textGrey)),
      ]),
    );
  }
}
