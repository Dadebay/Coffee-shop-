import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/ingredients_controller.dart';
import '../../core/constants/color_constants.dart';
import '../../data/database/app_database.dart';
import 'widgets/ingredient_tile.dart';
import 'widgets/ingredient_form_dialog.dart';
import 'widgets/ingredient_detail_panel.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  Ingredient? _selected;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<IngredientsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : const Color(0xFFF4F4F8);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Obx(() {
                    if (ctrl.loading.value) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary2));
                    }
                    if (ctrl.ingredients.isEmpty) return _EmptyState();
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w < 460
                            ? 2
                            : w < 700
                                ? 3
                                : 4;
                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 104,
                          ),
                          itemCount: ctrl.ingredients.length,
                          itemBuilder: (_, i) {
                            final ing = ctrl.ingredients[i];
                            return IngredientTile(
                              ingredient: ing,
                              selected: _selected?.id == ing.id,
                              onTap: () => setState(() => _selected = ing),
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
                if (_selected != null)
                  IngDetailPanel(
                    ingredient: _selected!,
                    onClose: () => setState(() => _selected = null),
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ing_title'.tr,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Obx(() {
                final count =
                    Get.find<IngredientsController>().ingredients.length;
                return Text(
                  '$count ${'ing_count'.tr}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
                  ),
                );
              }),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => Get.dialog(const IngredientFormDialog()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 18,
                color: Colors.white),
            label: Text(
              'ing_add'.tr,
              style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedWarehouse,
                size: 40,
                color: AppColors.primary2),
          ),
          const SizedBox(height: 16),
          Text(
            'ing_empty'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textGrey
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.dialog(const IngredientFormDialog()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary2),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 16,
                color: Colors.white),
            label: Text('ing_add'.tr,
                style: const TextStyle(fontFamily: 'Gilroy')),
          ),
        ],
      ),
    );
  }
}
