import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/pos_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/database_controller.dart';
import '../../../controllers/print_controller.dart';
import '../../../controllers/stock_controller.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/permissions.dart';
import '../../../core/widgets/touch_numpad.dart';
import '../../../core/widgets/numpad.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paidCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: '');
  String _method = 'cash';
  bool _loading = false;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  // "10" → 10 TMT;  "10%" → 10% of base
  double _parseDiscount(double base) {
    final t = _discCtrl.text.trim();
    if (t.endsWith('%')) {
      final pct = double.tryParse(t.substring(0, t.length - 1)) ?? 0;
      return (base * pct / 100).clamp(0.0, base);
    }
    return (double.tryParse(t) ?? 0).clamp(0.0, base);
  }

  void _onNumpadTap(String val) {
    if (val == '⌫') {
      if (_paidCtrl.text.isNotEmpty) {
        _paidCtrl.text = _paidCtrl.text.substring(0, _paidCtrl.text.length - 1);
      }
    } else if (val == '.') {
      if (!_paidCtrl.text.contains('.')) {
        _paidCtrl.text = _paidCtrl.text.isEmpty ? '0.' : '${_paidCtrl.text}.';
      }
    } else {
      _paidCtrl.text += val;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = CartController.to;
    final sub = cart.subTotal;
    final itemDisc = cart.totalItemDiscount;
    final orderDisc = _parseDiscount(sub - itemDisc);
    final total = (sub - itemDisc - orderDisc).clamp(0.0, double.infinity);
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final change = (paid - total).clamp(0.0, double.infinity);
    final canConfirm = !_loading && paid >= total && paid > 0;

    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final cardBg = isDark ? AppColors.bgCard : const Color(0xFFF8FAFF);
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 740,
        height: 560,
        child: Row(
          children: [
            // ── Left panel: summary ──────────────────────────────────────
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(22)),
                border: Border(right: BorderSide(color: border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary2.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCreditCard,
                              color: AppColors.primary2,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'pay_title'.tr,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: Get.back,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.bgBorder
                                  : const Color(0xFFEEF0F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: AppColors.textGrey,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: border, height: 1),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order summary
                          _SummaryRow(
                              label: 'pos_subtotal'.tr,
                              value: formatCurrency(sub),
                              isDark: isDark),
                          if (itemDisc > 0) ...[
                            const SizedBox(height: 6),
                            _SummaryRow(
                                label: 'pos_discount'.tr,
                                value: '- ${formatCurrency(itemDisc)}',
                                isDark: isDark,
                                valueColor: AppColors.red),
                          ],
                          const SizedBox(height: 10),

                          // Order-level discount input
                          Row(
                            children: [
                              Text(
                                '${'pos_discount'.tr}:',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final res = await showNumPad(
                                      context, _discCtrl,
                                      label: 'pos_discount'.tr,
                                      allowDecimal: true,
                                      allowPercent: true,
                                    );
                                    if (res != null) setState(() {});
                                  },
                                  child: Container(
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.bgSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: border),
                                    ),
                                    child: IgnorePointer(
                                      child: TextField(
                                        controller: _discCtrl,
                                        style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          Divider(color: border, height: 1),
                          const SizedBox(height: 14),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'pos_total'.tr,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                formatCurrency(total),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: AppColors.primary2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Payment method
                          Text(
                            'pay_title'.tr,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              color: AppColors.textGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _MethodBtn(
                                  icon: HugeIcons.strokeRoundedMoney02,
                                  label: 'pay_method_cash'.tr,
                                  selected: _method == 'cash',
                                  isDark: isDark,
                                  onTap: () => setState(() => _method = 'cash'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MethodBtn(
                                  icon: HugeIcons.strokeRoundedCreditCard,
                                  label: 'pay_method_card'.tr,
                                  selected: _method == 'card',
                                  isDark: isDark,
                                  onTap: () => setState(() => _method = 'card'),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Change display
                          if (paid > total)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.green.withAlpha(isDark ? 30 : 18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.green.withAlpha(60)),
                              ),
                              child: Row(
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle01,
                                    color: AppColors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'pay_change'.tr,
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 11,
                                          color: AppColors.green,
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(change),
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.bgCard
                                    : const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'pay_amount'.tr,
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  Text(
                                    paid > 0 ? formatCurrency(paid) : '—',
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: paid > 0
                                          ? (isDark
                                              ? AppColors.textWhite
                                              : const Color(0xFF0F172A))
                                          : AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right panel: numpad ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount display
                    Container(
                      height: 52,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMoney02,
                            size: 18,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paidCtrl.text.isEmpty ? '0.00' : _paidCtrl.text,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: _paidCtrl.text.isEmpty
                                    ? AppColors.textDim
                                    : (isDark
                                        ? AppColors.textWhite
                                        : const Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                          if (_paidCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _paidCtrl.clear()),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withAlpha(18),
                                  borderRadius: BorderRadius.circular(7),
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
                    ),
                    const SizedBox(height: 10),

                    // Quick chips
                    Row(
                      children:
                          [total, total + 5, total + 10, total + 50].map((v) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                _paidCtrl.text = v.toStringAsFixed(2);
                                setState(() {});
                              },
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: border),
                                ),
                                child: Center(
                                  child: Text(
                                    formatCurrency(v),
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Numpad
                    Expanded(
                      child: TouchNumpad(
                        onTap: _onNumpadTap,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: canConfirm
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary2
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: canConfirm
                              ? null
                              : (isDark
                                  ? AppColors.bgBorder
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: canConfirm ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : HugeIcon(
                                  icon:
                                      HugeIcons.strokeRoundedCheckmarkCircle01,
                                  size: 20,
                                  color: canConfirm
                                      ? Colors.white
                                      : AppColors.textGrey,
                                ),
                          label: Text(
                            'pay_confirm'.tr,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: canConfirm
                                  ? Colors.white
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final orderDisc = _parseDiscount(sub - itemDisc);

    final auth = Get.find<AuthController>();
    if (orderDisc > (sub * 0.10) && !auth.can(Permission.applyDiscount)) {
      final approved = await auth.requireAdmin('auth_req_discount'.tr);
      if (!approved) return;
    }

    final total = (sub - itemDisc - orderDisc).clamp(0.0, double.infinity);
    final paid = double.tryParse(_paidCtrl.text) ?? total;

    setState(() => _loading = true);
    try {
      final pos = Get.find<PosController>();
      final order = await pos.placeOrder(
        paid: paid,
        paymentMethod: _method,
        orderDiscount: orderDisc,
      );
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      pos.loadProducts();
      if (Get.isRegistered<StockController>()) StockController.to.loadIngredients();

      // Auto-print receipt
      if (Get.isRegistered<PrintController>()) {
        final printCtrl = PrintController.to;
        if (printCtrl.autoPrint.value &&
            printCtrl.selectedPrinter.value.isNotEmpty) {
          final db = Get.find<DatabaseController>().db;
          final items = await db.getOrderItems(order.id);
          printCtrl.printReceipt(order, items);
        }
      }

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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.isDark,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 13)),
        Text(value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ??
                  (isDark ? AppColors.textWhite : const Color(0xFF0F172A)),
            )),
      ],
    );
  }
}

class _MethodBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _MethodBtn(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.primary2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? c.withAlpha(isDark ? 35 : 20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? c
                : (isDark ? AppColors.bgBorder : const Color(0xFFDDE1EE)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
                icon: icon, color: selected ? c : AppColors.textGrey, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected ? c : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
