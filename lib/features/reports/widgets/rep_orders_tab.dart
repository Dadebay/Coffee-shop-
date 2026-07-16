import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/reports_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import 'order_detail_dialog.dart';

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
              final dateStr = formatDate(dt);
              final timeStr = formatTime(dt);
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

