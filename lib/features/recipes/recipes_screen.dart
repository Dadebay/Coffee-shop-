import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/recipes_controller.dart';
import '../../core/constants/color_constants.dart';
import 'widgets/rec_widgets.dart';

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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _search,
                        onChanged: (v) =>
                            setState(() => _query = v.toLowerCase()),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'pos_search'.tr,
                          hintStyle: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              size: 16,
                              color: AppColors.textGrey,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: HugeIcon(
                                      icon:
                                          HugeIcons.strokeRoundedCancel01,
                                      size: 14,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
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
                Expanded(
                  child: Obx(() {
                    final all = ctrl.products;
                    final filtered = _query.isEmpty
                        ? all
                        : all
                            .where((p) =>
                                p.name.toLowerCase().contains(_query))
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
                        final selected =
                            ctrl.selectedProduct.value?.id == p.id;
                        return RecProductTile(
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
                ? RecEmptyRight(isDark: isDark)
                : RecipeEditor(ctrl: ctrl)),
          ),
        ],
      ),
    );
  }
}
