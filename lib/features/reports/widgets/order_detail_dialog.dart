import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/database_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

void showOrderDetail(BuildContext context, Order order, String cashierName) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final db = Get.find<DatabaseController>().db;
  final cardColor = isDark ? AppColors.bgCard : Colors.white;
  final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
  final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

  final dt = order.createdAt;
  final dateStr = '${formatDate(dt)}  ${formatTime(dt)}';

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
                    Text('$cashierName  ·  $dateStr',
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            color: AppColors.textGrey)),
                  ])),
              GestureDetector(
                  onTap: Get.back,
                  child: const Icon(Icons.close,
                      color: AppColors.textGrey, size: 20)),
            ]),
          ),
          Divider(color: borderColor, height: 1),
          // Items
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
                  Text(
                      '${'rep_disc_short'.tr}: ${formatCurrency(order.discount)}',
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
        ],
      ),
    ),
  ));
}
