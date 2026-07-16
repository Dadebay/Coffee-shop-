import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/recipes_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/numpad.dart';
import 'rec_common.dart';
import 'recipe_row.dart';

// ── Recipe editor ─────────────────────────────────────────────────────────────
class RecipeEditor extends StatelessWidget {
  final RecipesController ctrl;
  const RecipeEditor({super.key, required this.ctrl});

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
              Obx(() {
                final cost = ctrl.totalCost.value;
                final profit = discountedPrice - cost;
                return Row(
                  children: [
                    RecStatBadge(
                      label: 'rec_cost'.tr,
                      value: formatCurrency(cost),
                      color: AppColors.red,
                      icon: HugeIcons.strokeRoundedMoney02,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    RecStatBadge(
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
                        _col('ing_stock'.tr, 2),
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
                        return RecipeRow(
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
        child: ConstrainedBox(
          // Cap the height instead of forcing it — the dialog was rendering
          // almost full-screen tall with a large blank area below the
          // content, which is much shorter than that.
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: dialogMaxHeight(ctx, margin: 80),
          ),
          child: Container(
            width: 380,
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
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i.name)))
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
