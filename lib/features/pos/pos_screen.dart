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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search row ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.bgBorder : const Color(0xFFE2E6F0),
                    ),
                    boxShadow: isDark
                        ? []
                        : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 13),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: AppColors.textGrey,
                        size: 15,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'pos_search'.tr,
                            hintStyle: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              color: isDark ? AppColors.textGrey : const Color(0xFFADB5C8),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => pos.search.value = v,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TopBarBtn(
                icon: HugeIcons.strokeRoundedReturnRequest,
                color: AppColors.red,
                tooltip: 'pos_returns'.tr,
                onTap: () => Get.dialog(const ReturnPanel()),
              ),
              const SizedBox(width: 6),
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
          const SizedBox(height: 10),

          // ── Category chips ──
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
                      onTap: () => pos.selectCategory(c.id),
                    )),
              ],
            ),
          )),
          const SizedBox(height: 10),
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

class _CatChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  State<_CatChip> createState() => _CatChipState();
}

class _CatChipState extends State<_CatChip> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const c = AppColors.primary2;
    final sel = widget.selected;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hov = true),
        onExit: (_) => setState(() => _hov = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? c
                  : (_hov
                      ? c.withAlpha(isDark ? 30 : 18)
                      : (isDark ? AppColors.bgCard : Colors.white)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? c
                    : (_hov
                        ? c.withAlpha(120)
                        : (isDark ? AppColors.bgBorder : const Color(0xffDDE1EE))),
                width: sel ? 0 : 1,
              ),
              boxShadow: sel
                  ? [BoxShadow(color: c.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel) ...[
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel
                        ? Colors.white
                        : (_hov ? c : AppColors.textGrey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
