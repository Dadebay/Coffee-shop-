import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../controllers/database_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

class ReturnPanel extends StatefulWidget {
  const ReturnPanel({super.key});

  @override
  State<ReturnPanel> createState() => _ReturnPanelState();
}

class _ReturnPanelState extends State<ReturnPanel> {
  final _db = Get.find<DatabaseController>().db;
  List<Order> _orders = [];
  Map<int, List<OrderItem>> _itemsMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final today = await _db.getOrdersForDay(DateTime.now());
    final activeOrders = today.where((o) => !o.isReturned).toList();
    final map = <int, List<OrderItem>>{};
    for (final o in activeOrders) {
      map[o.id] = await _db.getOrderItems(o.id);
    }
    if (mounted) {
      setState(() {
        _orders = activeOrders;
        _itemsMap = map;
        _loading = false;
      });
    }
  }

  Future<void> _doReturn(Order order) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedReturnRequest,
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pos_return'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'pos_return_confirm'.tr,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'pos_total'.tr,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      formatCurrency(order.total),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('gen_cancel'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                      child: Text('pos_return'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final user = AuthController.to.currentUser.value;
      if (user == null) return;
      try {
        await _db.cancelOrder(order.id, user.id);
        Get.snackbar(
          'gen_success'.tr,
          '#${order.id} ${'pos_return_done'.tr}',
          backgroundColor: AppColors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        await _load();
      } catch (e) {
        Get.snackbar('gen_error'.tr, e.toString(),
            backgroundColor: AppColors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE0E0E6);
    final cardColor = isDark ? AppColors.bgCard : Colors.white;

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedReturnRequest,
                        color: AppColors.red,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'pos_returns'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 20,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary2))
                  : _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedReturnRequest,
                                size: 52,
                                color: AppColors.textDim,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'pos_no_orders_today'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final order = _orders[i];
                            final orderItems = _itemsMap[order.id] ?? [];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary2.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${order.id}',
                                          style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: AppColors.primary2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(order.createdAt),
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          color: AppColors.textGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _PayMethodBadge(method: order.paymentMethod),
                                      const Spacer(),
                                      Text(
                                        formatCurrency(order.total),
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (orderItems.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...orderItems.map((it) => Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            '${it.quantity}× ${it.productName}  ${formatCurrency(it.total)}',
                                            style: const TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 12,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        )),
                                  ],
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _doReturn(order),
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedReturnRequest,
                                        size: 15,
                                        color: AppColors.red,
                                      ),
                                      label: Text(
                                        'pos_return'.tr,
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.red,
                                        side: BorderSide(
                                            color: AppColors.red.withAlpha(80)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PayMethodBadge extends StatelessWidget {
  final String method;
  const _PayMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    switch (method) {
      case 'card':
        c = AppColors.primary2;
        label = 'pay_method_card'.tr;
        break;
      case 'mixed':
        c = AppColors.orange;
        label = 'pay_method_mixed'.tr;
        break;
      default:
        c = AppColors.green;
        label = 'pay_method_cash'.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}
