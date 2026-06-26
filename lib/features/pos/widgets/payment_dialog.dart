import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/pos_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paidCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: '0');
  String _method = 'cash';
  bool _loading = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.to;
    final sub = cart.subTotal;
    final itemDisc = cart.totalItemDiscount;
    final orderDisc = double.tryParse(_discCtrl.text) ?? 0;
    final total = (sub - itemDisc - orderDisc).clamp(0.0, double.infinity);
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final change = (paid - total).clamp(0.0, double.infinity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  color: AppColors.primary2,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'pay_title'.tr,
                  style: const TextStyle(
                      fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: Get.back,
                ),
              ],
            ),
            const Divider(color: AppColors.bgBorder, height: 24),

            _Line('pos_subtotal'.tr, formatCurrency(sub)),
            if (itemDisc > 0)
              _Line('pos_discount'.tr, '- ${formatCurrency(itemDisc)}',
                  color: AppColors.red),
            const SizedBox(height: 10),

            // Order discount
            Row(
              children: [
                Text('${'pos_discount'.tr}:',
                    style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.textGrey,
                        fontSize: 13)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _discCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
                    decoration: const InputDecoration(
                        isDense: true, contentPadding: EdgeInsets.all(10)),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Line('pos_total'.tr, formatCurrency(total),
                large: true, color: AppColors.primary2),
            const Divider(color: AppColors.bgBorder, height: 24),

            // Payment method
            Text('pay_title'.tr,
                style: const TextStyle(
                    fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodBtn(
                    icon: HugeIcons.strokeRoundedMoney02,
                    label: 'pay_method_cash'.tr,
                    selected: _method == 'cash',
                    onTap: () => setState(() => _method = 'cash')),
                const SizedBox(width: 8),
                _MethodBtn(
                    icon: HugeIcons.strokeRoundedCreditCard,
                    label: 'pay_method_card'.tr,
                    selected: _method == 'card',
                    onTap: () => setState(() => _method = 'card')),
              ],
            ),
            const SizedBox(height: 16),

            // Paid amount
            TextField(
              controller: _paidCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15),
              decoration: InputDecoration(
                labelText: 'pay_amount'.tr,
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoney02,
                  size: 18,
                  color: AppColors.textGrey,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Quick amount chips
            Wrap(
              spacing: 6,
              children: [total, total + 5, total + 10, total + 50]
                  .map((v) => GestureDetector(
                        onTap: () {
                          _paidCtrl.text = v.toStringAsFixed(2);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.bgBorder),
                          ),
                          child: Text(
                            formatCurrency(v),
                            style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Change
            if (paid > total) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.green.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      color: AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${'pay_change'.tr}: ${formatCurrency(change)}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_loading || paid < total) ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        size: 20,
                        color: Colors.white,
                      ),
                label: Text(
                  'pay_confirm'.tr,
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final cart = CartController.to;
    final sub = cart.subTotal;
    final itemDisc = cart.totalItemDiscount;
    final orderDisc = double.tryParse(_discCtrl.text) ?? 0;
    final total = (sub - itemDisc - orderDisc).clamp(0.0, double.infinity);
    final paid = double.tryParse(_paidCtrl.text) ?? total;

    setState(() => _loading = true);
    try {
      await Get.find<PosController>().placeOrder(
        paid: paid,
        paymentMethod: _method,
        orderDiscount: orderDisc,
      );
      Get.back();
      Get.snackbar(
        'gen_success'.tr,
        'pos_pay'.tr,
        backgroundColor: AppColors.green.withAlpha(200),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('gen_error'.tr, e.toString(),
          backgroundColor: AppColors.red.withAlpha(200),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  final Color? color;
  const _Line(this.label, this.value, {this.large = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: large ? 17 : 13,
                  fontWeight: large ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.textGrey)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: large ? 17 : 13,
                  fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                  color: c)),
        ],
      ),
    );
  }
}

class _MethodBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodBtn(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.primary2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c : AppColors.bgBorder),
        ),
        child: Row(
          children: [
            HugeIcon(
                icon: icon, color: selected ? c : AppColors.textGrey, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: selected ? c : AppColors.textGrey,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}
