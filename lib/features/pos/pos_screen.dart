import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/pos_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../core/constants/color_constants.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/return_panel.dart';
import 'widgets/shift_dialogs.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    // Check for open shift on POS screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shift = ShiftController.to;
      if (!shift.isOpen) {
        Get.dialog(
          const OpenShiftDialog(),
          barrierDismissible: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();
    final cart = CartController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xffEEEEF2);
    final borderColor  = isDark ? AppColors.bgBorder  : const Color(0xffE0E0E6);

    return Scaffold(
      body: Row(
        children: [
          // ── Left: products ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildTopBar(context, pos, surfaceColor, borderColor),
                Expanded(
                  child: Obx(() {
                    if (pos.loadingProducts.value) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary2));
                    }
                    if (pos.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedPackageOpen,
                              size: 48,
                              color: AppColors.textDim,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'pos_no_products'.tr,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                color: AppColors.textGrey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ProductGrid(
                      products: pos.products,
                      onTap: cart.addProduct,
                    );
                  }),
                ),
              ],
            ),
          ),
          // ── Right: cart ──────────────────────────────────────────────────
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(left: BorderSide(color: borderColor)),
            ),
            child: CartPanel(
              onCheckout: () => Get.dialog(
                const PaymentDialog(),
                barrierDismissible: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PosController pos,
      Color surfaceColor, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'pos_search'.tr,
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: AppColors.textGrey,
                      size: 18,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'Gilroy'),
                  onChanged: (v) => pos.search.value = v,
                ),
              ),
              const SizedBox(width: 8),
              // İade (Return) button
              _TopBarBtn(
                icon: HugeIcons.strokeRoundedReturnRequest,
                color: AppColors.red,
                tooltip: 'pos_returns'.tr,
                onTap: () => Get.dialog(const ReturnPanel()),
              ),
              const SizedBox(width: 6),
              // Shift button
              Obx(() {
                final isOpen = ShiftController.to.isOpen;
                return _TopBarBtn(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: isOpen ? AppColors.green : AppColors.red,
                  tooltip: isOpen ? 'shift_close'.tr : 'shift_open'.tr,
                  onTap: () {
                    if (isOpen) {
                      Get.dialog(CloseShiftDialog(
                          shift: ShiftController.to.activeShift.value!));
                    } else {
                      Get.dialog(const OpenShiftDialog(),
                          barrierDismissible: false);
                    }
                  },
                  badge: isOpen,
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CatChip(
                  label: 'pos_all'.tr,
                  selected: pos.selectedCategory.value == null,
                  onTap: () => pos.selectCategory(null),
                ),
                ...pos.categories.map((c) => _CatChip(
                      label: c.name,
                      selected: pos.selectedCategory.value == c.id,
                      color: _hexColor(c.color),
                      onTap: () => pos.selectCategory(c.id),
                    )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary2;
    }
  }
}

class _TopBarBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  const _TopBarBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Center(
                child: HugeIcon(icon: icon, size: 18, color: color),
              ),
            ),
            if (badge)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.bgSurface : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.primary2;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? c.withAlpha(40)
                : (isDark ? AppColors.bgCard : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? c
                  : (isDark ? AppColors.bgBorder : const Color(0xffE0E0E6)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? c : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
