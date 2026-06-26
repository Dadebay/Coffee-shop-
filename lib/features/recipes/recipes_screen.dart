import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/recipes_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RecipesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xFFF0F2F8);
    final borderColor  = isDark ? AppColors.bgBorder  : const Color(0xFFE2E8F0);

    return Scaffold(
      body: Row(
        children: [
          // Left: product list
          Container(
            width: 260,
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    'Ürün Seç',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Divider(color: borderColor, height: 1),
                Expanded(
                  child: Obx(() => ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        itemCount: ctrl.products.length,
                        itemBuilder: (_, i) {
                          final p = ctrl.products[i];
                          final selected = ctrl.selectedProduct.value?.id == p.id;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withAlpha(isDark ? 30 : 20)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withAlpha(80)
                                    : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary2
                                      : (isDark ? AppColors.textWhite : const Color(0xFF0F172A)),
                                ),
                              ),
                              subtitle: Text(
                                formatCurrency(p.price),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
                                ),
                              ),
                              onTap: () => ctrl.selectProduct(p),
                            ),
                          );
                        },
                      )),
                ),
              ],
            ),
          ),
          VerticalDivider(color: borderColor, width: 1),
          // Right: recipe editor
          Expanded(
            child: Obx(() => ctrl.selectedProduct.value == null
                ? Center(
                    child: Text(
                      'Sol taraftan ürün seçin',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : _RecipeEditor(ctrl: ctrl)),
          ),
        ],
      ),
    );
  }
}

class _RecipeEditor extends StatelessWidget {
  final RecipesController ctrl;
  const _RecipeEditor({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = isDark ? AppColors.bgCard    : Colors.white;
    final surfaceColor= isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);
    final borderColor = isDark ? AppColors.bgBorder  : const Color(0xFFE2E8F0);
    final textColor   = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    final p = ctrl.selectedProduct.value!;
    final discountedPrice = p.discountType == 'percentage'
        ? p.price - p.price * p.discount / 100
        : p.price - p.discount;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Satış: ${formatCurrency(discountedPrice)}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.primary2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() {
                final cost = ctrl.totalCost.value;
                final profit = discountedPrice - cost;
                return Row(
                  children: [
                    _CostBadge('Maliyet', formatCurrency(cost), AppColors.blue),
                    const SizedBox(width: 8),
                    _CostBadge('Kâr', formatCurrency(profit),
                        profit >= 0 ? AppColors.green : AppColors.red),
                    const SizedBox(width: 8),
                    _CostBadge(
                      'Oran',
                      cost > 0 ? '%${(profit / cost * 100).toStringAsFixed(1)}' : '-',
                      AppColors.orange,
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: Colors.white),
                      label: const Text(
                        'Malzeme Ekle',
                        style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Obx(() {
              if (ctrl.recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedBook02,
                        size: 56,
                        color: isDark ? AppColors.textDim : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz malzeme eklenmemiş',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _showAddDialog(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: Colors.white),
                        label: const Text('Malzeme Ekle', style: TextStyle(fontFamily: 'Gilroy')),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _headerCell('Malzeme', 3),
                        _headerCell('Miktar', 2),
                        _headerCell('Birim Maliyet', 2),
                        _headerCell('Toplam', 2),
                        const SizedBox(width: 72),
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
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark
                                ? []
                                : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  ing.name,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${r.quantity.toStringAsFixed(3)} ${ing.unit}',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${formatCurrency(ing.cost)}/${ing.unit}',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: isDark ? AppColors.textDim : const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrency(lineCost),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.primary2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 72,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, size: 16, color: AppColors.textGrey),
                                      onPressed: () => _showEditDialog(context, r, ing),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    IconButton(
                                      icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: AppColors.red),
                                      onPressed: () => ctrl.removeRecipe(r.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, int flex) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
      );

  void _showAddDialog(BuildContext context) {
    final ing = Get.find<RecipesController>().allIngredients;
    final existing = ctrl.recipes.map((r) => r.ingredientId).toList();
    final available = ing.where((i) => !existing.contains(i.id)).toList();
    if (available.isEmpty) {
      Get.snackbar('Bilgi', 'Tüm malzemeler zaten eklenmiş',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Ingredient? sel;
    final qtyCtrl = TextEditingController();

    Get.dialog(StatefulBuilder(builder: (ctx, setState) {
      final isDarkInner = Theme.of(ctx).brightness == Brightness.dark;
      final bgColor = isDarkInner ? AppColors.bgSurface : Colors.white;
      final borderColor = isDarkInner ? AppColors.bgBorder : const Color(0xFFE2E8F0);
      final textColor = isDarkInner ? AppColors.textWhite : const Color(0xFF0F172A);

      return Dialog(
        backgroundColor: Colors.transparent,
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
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: AppColors.primary2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Malzeme Ekle',
                      style: TextStyle(
                        fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.close_rounded, size: 15, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Divider(color: borderColor, height: 1),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Ingredient>(
                      value: sel,
                      dropdownColor: isDarkInner ? AppColors.bgCard : Colors.white,
                      style: TextStyle(fontFamily: 'Gilroy', color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Malzeme',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: isDarkInner ? AppColors.textGrey : const Color(0xFF64748B)),
                        filled: true,
                        fillColor: isDarkInner ? AppColors.bgCard : const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
                      ),
                      items: available.map((i) => DropdownMenuItem(
                        value: i,
                        child: Text('${i.name} (${i.stock.toStringAsFixed(2)} ${i.unit})'),
                      )).toList(),
                      onChanged: (v) => setState(() => sel = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontFamily: 'Gilroy', color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'rec_qty'.tr,
                        suffixText: sel?.unit ?? '',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: isDarkInner ? AppColors.textGrey : const Color(0xFF64748B)),
                        filled: true,
                        fillColor: isDarkInner ? AppColors.bgCard : const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('İptal', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: sel == null ? null : () async {
                              final qty = double.tryParse(qtyCtrl.text);
                              if (qty != null && qty > 0) {
                                await ctrl.addIngredient(sel!.id, qty);
                                Get.back();
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Ekle', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
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
      );
    }));
  }

  void _showEditDialog(BuildContext context, Recipe recipe, Ingredient ing) {
    final ctrl2 = TextEditingController(text: recipe.quantity.toStringAsFixed(3));
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
              offset: const Offset(0, 8),
            ),
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
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, size: 16, color: AppColors.primary2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Miktar: ${ing.name}',
                      style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 15, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.close_rounded, size: 15, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(color: borderColor, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  TextFormField(
                    controller: ctrl2,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: TextStyle(fontFamily: 'Gilroy', color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Miktar (${ing.unit})',
                      labelStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: isDark ? AppColors.textGrey : const Color(0xFF64748B)),
                      filled: true,
                      fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('İptal', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Kaydet', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
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

class _CostBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CostBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Gilroy', color: color.withAlpha(180), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
