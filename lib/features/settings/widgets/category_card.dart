import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../controllers/products_controller.dart';
import '../../../core/constants/color_constants.dart';

// ── Category card ─────────────────────────────────────────────────────────────
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key});

  static const _palette = [
    '#E8724A',
    '#187bff',
    '#3ead2c',
    '#fedb00',
    '#FF3B30',
    '#9B59B6',
    '#1ABC9C',
    '#E67E22',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    final ctrl = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());

    return Obx(() {
      final cats = ctrl.categories;

      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            ...cats.asMap().entries.map((e) {
              final cat = e.value;
              final color = _hexColor(cat.color);
              return Container(
                decoration: BoxDecoration(
                  border: e.key < cats.length - 1
                      ? Border(bottom: BorderSide(color: borderColor))
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      CatIconBtn(
                        hugeIcon: HugeIcons.strokeRoundedEdit02,
                        color: AppColors.primary2,
                        onTap: () => _showCatDialog(context, ctrl, cat: cat),
                      ),
                      const SizedBox(width: 4),
                      CatIconBtn(
                        hugeIcon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.red,
                        onTap: () => _confirmDelete(context, ctrl, cat),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (cats.isNotEmpty) Divider(color: borderColor, height: 1),
            InkWell(
              onTap: () => _showCatDialog(context, ctrl),
              borderRadius: BorderRadius.vertical(
                top: cats.isEmpty ? const Radius.circular(14) : Radius.zero,
                bottom: const Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 15,
                          color: AppColors.primary2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'set_cat_add'.tr,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showCatDialog(BuildContext context, ProductsController ctrl,
      {Category? cat}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    String selectedColor = cat?.color ?? _palette[0];

    Get.dialog(StatefulBuilder(builder: (ctx, setState) {
      final bg = isDark ? AppColors.bgSurface : Colors.white;
      final borderColor =
          isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: bg,
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
                          icon: HugeIcons.strokeRoundedGrid,
                          size: 16,
                          color: AppColors.primary2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      cat == null ? 'set_cat_new'.tr : 'set_cat_edit'.tr,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textColor),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(7)),
                        child: HugeIcon(
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
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: textColor),
                      decoration: InputDecoration(
                        labelText: 'set_cat_name'.tr,
                        labelStyle: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textGrey
                                : const Color(0xFF64748B)),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.bgCard
                            : const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
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
                    const SizedBox(height: 16),
                    Text('set_cat_color'.tr,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textGrey
                                : const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _palette.map((hex) {
                        final color = _hexColor(hex);
                        final sel = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: color.withAlpha(120),
                                          blurRadius: 6)
                                    ]
                                  : [],
                            ),
                            child: sel
                                ? HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle01,
                                    size: 14,
                                    color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              if (cat == null) {
                                await ctrl.addCategory(name, selectedColor);
                              } else {
                                await ctrl.updateCategory(
                                    cat, name, selectedColor);
                              }
                              Get.back();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                                cat == null ? 'gen_add'.tr : 'gen_save'.tr,
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
      );
    }));
  }

  void _confirmDelete(
      BuildContext context, ProductsController ctrl, Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 60 : 15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(15),
                  shape: BoxShape.circle),
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: AppColors.red,
                  size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              '"${cat.name}" ${'set_cat_delete_title'.tr}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'set_cat_delete_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textGrey
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    side:
                        BorderSide(color: Colors.grey.withAlpha(60)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_cancel'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await ctrl.deleteCategory(cat.id);
                    Get.back();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_delete'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ));
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ── Category icon button ──────────────────────────────────────────────────────
class CatIconBtn extends StatelessWidget {
  final dynamic hugeIcon;
  final Color color;
  final VoidCallback onTap;
  const CatIconBtn(
      {super.key, this.hugeIcon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: HugeIcon(
            icon: hugeIcon ?? HugeIcons.strokeRoundedEdit02,
            size: 14,
            color: color),
      ),
    );
  }
}

