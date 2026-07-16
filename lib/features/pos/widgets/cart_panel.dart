import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/cart_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pricing.dart';
import '../../../core/widgets/numpad.dart';
import '../../../data/models/cart_item.dart';

class CartPanel extends StatelessWidget {
  final VoidCallback? onCheckout;
  const CartPanel({super.key, this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE0E0E6);
    final cardColor = isDark ? AppColors.bgCard : Colors.white;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedShoppingCart01,
                color: AppColors.primary2,
                size: 20,
              ),
              const SizedBox(width: 8),
              Obx(() => Text(
                    '${'pos_cart'.tr} (${cart.items.length})',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  )),
              const Spacer(),
              Obx(() => cart.items.isEmpty
                  ? const SizedBox.shrink()
                  : TextButton.icon(
                      onPressed: cart.clear,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 15,
                        color: AppColors.red,
                      ),
                      label: Text(
                        'gen_delete'.tr,
                        style:
                            const TextStyle(fontFamily: 'Gilroy', fontSize: 12),
                      ),
                      style:
                          TextButton.styleFrom(foregroundColor: AppColors.red),
                    )),
            ],
          ),
        ),

        // Items
        Expanded(
          child: Obx(() => cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedShoppingCart01,
                        size: 56,
                        color: AppColors.textDim,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'pos_cart_empty'.tr,
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
                  padding: const EdgeInsets.all(10),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return _CartTile(
                      key: ValueKey(item.product.id),
                      item: item,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    );
                  },
                )),
        ),

        // Summary + checkout
        Obx(() {
          final sub = cart.subTotal;
          final disc = cart.totalItemDiscount;
          final total = (sub - disc).clamp(0.0, double.infinity);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                _SummaryRow('pos_subtotal'.tr, sub),
                if (disc > 0)
                  _SummaryRow('pos_discount'.tr, -disc, color: AppColors.red),
                Divider(color: borderColor, height: 16),
                _SummaryRow('pos_total'.tr, total,
                    bold: true, color: AppColors.primary2),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: cart.items.isEmpty ? null : onCheckout,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCreditCard,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      '${'pos_pay'.tr}   ${formatCurrency(total)}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final Color cardColor;
  final Color borderColor;

  const _CartTile({
    super.key,
    required this.item,
    required this.cardColor,
    required this.borderColor,
  });

  void _showDiscountDialog() {
    Get.dialog(_DiscountDialog(item: item));
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final qtyColor = isDark ? AppColors.textWhite : const Color(0xFF1E293B);
    final totalColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final discBtnBg = isDark ? AppColors.bgBorder : const Color(0xFFEEF0F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(item.unitPrice),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.primary2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Discount button
              GestureDetector(
                onTap: _showDiscountDialog,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: item.extraDiscount > 0
                        ? AppColors.red.withAlpha(isDark ? 40 : 20)
                        : discBtnBg,
                    borderRadius: BorderRadius.circular(8),
                    border: item.extraDiscount > 0
                        ? Border.all(color: AppColors.red.withAlpha(60))
                        : null,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPercentCircle,
                      size: 13,
                      color: item.extraDiscount > 0
                          ? AppColors.red
                          : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
              _QtyBtn(
                icon: HugeIcons.strokeRoundedMinusSign,
                onTap: () => cart.decrement(item.product.id),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: qtyColor,
                  ),
                ),
              ),
              _QtyBtn(
                icon: HugeIcons.strokeRoundedAdd01,
                onTap: () => cart.increment(item.product.id),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 68,
                child: Text(
                  formatCurrency(item.lineTotal),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: totalColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => cart.removeItem(item.product.id),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.red.withAlpha(isDark ? 30 : 15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 12,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.extraDiscount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedPercentCircle,
                    size: 11,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${'pos_discount'.tr}: -${formatCurrency(item.extraDiscount)}',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Discount dialog ─────────────────────────────────────────────────────────
class _DiscountDialog extends StatefulWidget {
  final CartItem item;
  const _DiscountDialog({required this.item});

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.item.extraDiscount > 0
          ? widget.item.extraDiscount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _parseDiscount(double base) => parseDiscountInput(_ctrl.text, base);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxDiscount = widget.item.unitPrice * widget.item.quantity;

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedPercentCircle,
                    color: AppColors.primary2,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pos_discount'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.product.name,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              NumPadWidget(
                controller: _ctrl,
                label: '${'pos_discount'.tr} (max ${formatCurrency(maxDiscount)})',
                allowPercent: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text('gen_cancel'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final val = _parseDiscount(maxDiscount);
                        CartController.to
                            .setExtraDiscount(widget.item.product.id, val);
                        Get.back();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary2),
                      child: Text('gen_save'.tr,
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
  }
}

class _QtyBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgBorder : const Color(0xFFEEF0F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            size: 13,
            color: isDark ? AppColors.textWhite : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.textGrey;
    final labelColor = bold
        ? (isDark ? AppColors.textWhite : const Color(0xFF0F172A))
        : AppColors.textGrey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: labelColor,
              )),
          Text(formatCurrency(value.abs()),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: c,
              )),
        ],
      ),
    );
  }
}
