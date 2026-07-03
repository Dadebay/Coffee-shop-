import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/recipes_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/numpad.dart';
import '../../core/widgets/product_thumb.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RecipesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE8EAEF);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F5F8),
      body: Row(
        children: [
          // ── Left panel ─────────────────────────────────────────────
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'rec_title'.tr,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Search bar
                      TextField(
                        controller: _search,
                        onChanged: (v) =>
                            setState(() => _query = v.toLowerCase()),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'pos_search'.tr,
                          hintStyle: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              size: 16,
                              color: AppColors.textGrey,
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedCancel01,
                                      size: 14,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                )
                              : null,
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.bgCard
                              : const Color(0xFFF4F6FA),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary2, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product list
                Expanded(
                  child: Obx(() {
                    final all = ctrl.products;
                    final filtered = _query.isEmpty
                        ? all
                        : all
                            .where((p) => p.name.toLowerCase().contains(_query))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 32,
                                color: AppColors.textGrey),
                            const SizedBox(height: 8),
                            Text('pos_no_products'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.textGrey,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final selected = ctrl.selectedProduct.value?.id == p.id;
                        return _ProductTile(
                          product: p,
                          selected: selected,
                          isDark: isDark,
                          onTap: () => ctrl.selectProduct(p),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Right panel ────────────────────────────────────────────
          Expanded(
            child: Obx(() => ctrl.selectedProduct.value == null
                ? _EmptyRight(isDark: isDark)
                : _RecipeEditor(ctrl: ctrl)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state right panel ───────────────────────────────────────────────────
class _EmptyRight extends StatelessWidget {
  final bool isDark;
  const _EmptyRight({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBook02,
                  size: 34,
                  color: AppColors.primary2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'rec_select_left'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'rec_select_product'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              color: isDark ? AppColors.textDim : const Color(0xFFB0BAC9),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────
class _ProductTile extends StatefulWidget {
  final Product product;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _ProductTile(
      {required this.product,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final sel = widget.selected;
    final isDark = widget.isDark;

    final hoverColor = isDark ? AppColors.bgCard : const Color(0xFFF0F4FF);
    final bg = sel
        ? AppColors.primary2
        : _hovered
            ? hoverColor
            : hoverColor.withAlpha(0);

    final textColor = sel
        ? Colors.white
        : (isDark ? AppColors.textWhite : const Color(0xFF0F172A));

    final subColor = sel ? Colors.white.withAlpha(180) : AppColors.textGrey;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: AppColors.primary2.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            children: [
              ProductThumb(
                imagePath: p.imagePath,
                isDark: isDark,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatCurrency(p.price),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (sel)
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 16,
                    color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recipe editor ─────────────────────────────────────────────────────────────
class _RecipeEditor extends StatelessWidget {
  final RecipesController ctrl;
  const _RecipeEditor({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xFFF4F5F8);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE8EAEF);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    final p = ctrl.selectedProduct.value!;
    final discountedPrice = p.discountType == 'percentage'
        ? p.price - p.price * p.discount / 100
        : p.price - p.discount;

    return Column(
      children: [
        // ── Top bar ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Product info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedTag01,
                          size: 12,
                          color: AppColors.primary2),
                      const SizedBox(width: 4),
                      Text(
                        formatCurrency(discountedPrice),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.primary2,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Stat badges + button
              Obx(() {
                final cost = ctrl.totalCost.value;
                final profit = discountedPrice - cost;
                return Row(
                  children: [
                    _StatBadge(
                      label: 'rec_cost'.tr,
                      value: formatCurrency(cost),
                      color: AppColors.red,
                      icon: HugeIcons.strokeRoundedMoney02,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _StatBadge(
                      label: 'prod_profit'.tr,
                      value: formatCurrency(profit),
                      color: profit >= 0 ? AppColors.green : AppColors.red,
                      icon: HugeIcons.strokeRoundedTrendingUpDown,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 16,
                          color: Colors.white),
                      label: Text(
                        'rec_add_ingredient'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        // ── Table area ───────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (ctrl.recipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.bgCard : const Color(0xFFF1F3F8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBook02,
                          size: 30,
                          color: isDark
                              ? AppColors.textDim
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'rec_no_ingredients'.tr,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: isDark
                            ? AppColors.textGrey
                            : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 16,
                          color: Colors.white),
                      label: Text('rec_add_ingredient'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _col('rec_ingredient'.tr, 3),
                        _col('rec_qty'.tr, 2),
                        _col('ing_cost'.tr, 2),
                        _col('rec_total'.tr, 2),
                        const SizedBox(width: 68),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      itemCount: ctrl.recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final r = ctrl.recipes[i];
                        final ing = ctrl.ingredientById(r.ingredientId);
                        if (ing == null) return const SizedBox.shrink();
                        final lineCost = r.quantity * ing.cost;
                        return _RecipeRow(
                          recipe: r,
                          ingredient: ing,
                          lineCost: lineCost,
                          isDark: isDark,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          onEdit: () => _showEditDialog(context, r, ing),
                          onDelete: () => ctrl.removeRecipe(r.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _col(String label, int flex) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.4,
            color: AppColors.textGrey,
          ),
        ),
      );

  void _showAddDialog(BuildContext context) {
    final ing = Get.find<RecipesController>().allIngredients;
    final existing = ctrl.recipes.map((r) => r.ingredientId).toList();
    final available = ing.where((i) => !existing.contains(i.id)).toList();
    if (available.isEmpty) {
      Get.snackbar('gen_info'.tr, 'rec_all_added'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Ingredient? sel;
    final qtyCtrl = TextEditingController();

    Get.dialog(StatefulBuilder(builder: (ctx, setState) {
      final isDarkInner = Theme.of(ctx).brightness == Brightness.dark;
      final bgColor = isDarkInner ? AppColors.bgSurface : Colors.white;
      final borderColor =
          isDarkInner ? AppColors.bgBorder : const Color(0xFFE2E8F0);
      final textColor =
          isDarkInner ? AppColors.textWhite : const Color(0xFF0F172A);

      return Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 380,
          height: MediaQuery.of(ctx).size.height - 80,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(isDarkInner ? 60 : 15),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 18, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(9)),
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedAdd01,
                            size: 16,
                            color: AppColors.primary2),
                      ),
                      const SizedBox(width: 10),
                      Text('rec_add_ingredient'.tr,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: textColor)),
                      const Spacer(),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(7)),
                          child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 15,
                              color: AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Divider(color: borderColor, height: 1)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Ingredient>(
                        initialValue: sel,
                        dropdownColor:
                            isDarkInner ? AppColors.bgCard : Colors.white,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: textColor,
                            fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'rec_ingredient'.tr,
                          labelStyle: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              color: isDarkInner
                                  ? AppColors.textGrey
                                  : const Color(0xFF64748B)),
                          filled: true,
                          fillColor: isDarkInner
                              ? AppColors.bgCard
                              : const Color(0xFFF8FAFF),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary2, width: 1.5)),
                        ),
                        items: available
                            .map((i) => DropdownMenuItem(
                                value: i,
                                child: Text(
                                    '${i.name} (${i.stock.toStringAsFixed(2)} ${i.unit})')))
                            .toList(),
                        onChanged: (v) => setState(() => sel = v),
                      ),
                      const SizedBox(height: 12),
                      NumPadWidget(
                        controller: qtyCtrl,
                        label: 'rec_qty'.tr,
                        suffix: sel?.unit ?? '',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: Get.back,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(
                                    color: Colors.grey.withAlpha(60)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('gen_cancel'.tr,
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: sel == null
                                  ? null
                                  : () async {
                                      final qty = double.tryParse(qtyCtrl.text);
                                      if (qty != null && qty > 0) {
                                        await ctrl.addIngredient(sel!.id, qty);
                                        Get.back();
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('gen_add'.tr,
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  void _showEditDialog(BuildContext context, Recipe recipe, Ingredient ing) {
    final ctrl2 =
        TextEditingController(text: recipe.quantity.toStringAsFixed(3));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 60 : 15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(9)),
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        size: 16,
                        color: AppColors.primary2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(ing.name,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: textColor),
                        overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(7)),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 15,
                          color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Divider(color: borderColor, height: 1)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  TextFormField(
                    controller: ctrl2,
                    style: TextStyle(
                        fontFamily: 'Gilroy', color: textColor, fontSize: 14),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${('rec_qty'.tr)} (${ing.unit})',
                      labelStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textGrey
                              : const Color(0xFF64748B)),
                      filled: true,
                      fillColor:
                          isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary2, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.grey.withAlpha(60)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('gen_cancel'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final qty = double.tryParse(ctrl2.text);
                            if (qty != null && qty > 0) {
                              await ctrl.updateRecipeQty(recipe, qty);
                              Get.back();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary2,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('gen_save'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Recipe row ────────────────────────────────────────────────────────────────
class _RecipeRow extends StatefulWidget {
  final Recipe recipe;
  final Ingredient ingredient;
  final double lineCost;
  final bool isDark;
  final Color cardColor, borderColor, textColor;
  final VoidCallback onEdit, onDelete;

  const _RecipeRow({
    required this.recipe,
    required this.ingredient,
    required this.lineCost,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RecipeRow> createState() => _RecipeRowState();
}

class _RecipeRowState extends State<_RecipeRow> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final r = widget.recipe;

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _hov
              ? (widget.isDark
                  ? AppColors.bgCard.withAlpha(200)
                  : const Color(0xFFF8FAFF))
              : widget.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  _hov ? AppColors.primary.withAlpha(40) : widget.borderColor),
          boxShadow: widget.isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withAlpha(_hov ? 8 : 4),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: AppColors.primary2.withAlpha(160),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(ing.name,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: widget.textColor)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${r.quantity.toStringAsFixed(3)} ${ing.unit}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: widget.isDark
                        ? AppColors.textGrey
                        : const Color(0xFF64748B),
                    fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${formatCurrency(ing.cost)}/${ing.unit}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: widget.isDark
                        ? AppColors.textDim
                        : const Color(0xFF94A3B8),
                    fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary2.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatCurrency(widget.lineCost),
                    style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.primary2,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 68,
              child: Row(
                children: [
                  _IconBtn(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      color: AppColors.textGrey,
                      onTap: widget.onEdit),
                  const SizedBox(width: 4),
                  _IconBtn(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: AppColors.red,
                      onTap: widget.onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hov ? widget.color.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: HugeIcon(icon: widget.icon, size: 15, color: widget.color),
        ),
      ),
    );
  }
}

// ── Stat badge ────────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final List<List<dynamic>> icon;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(35) : color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withAlpha(isDark ? 100 : 80), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Solid left accent bar
          Container(
            width: 5,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          // Icon circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 60 : 35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: HugeIcon(icon: icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: color.withAlpha(isDark ? 200 : 170),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
