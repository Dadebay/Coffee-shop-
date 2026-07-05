import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/permissions.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import 'widgets/product_table.dart';
import 'widgets/product_form_dialog.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  String _query = '';
  int? _filterCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F4F8),
      body: Column(
        children: [
          _Header(onAdd: () => _openForm(ctrl)),
          _FilterBar(
            searchCtrl: _search,
            onSearch: (q) => setState(() => _query = q),
            onCategory: (id) => setState(() => _filterCategory = id),
            selectedCategory: _filterCategory,
          ),
          Expanded(
            child: Obx(() {
              if (ctrl.loading.value) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary2));
              }

              final list = ctrl.products.where((p) {
                final matchQ = _query.isEmpty ||
                    p.name.toLowerCase().contains(_query.toLowerCase()) ||
                    p.sku.toLowerCase().contains(_query.toLowerCase());
                final matchCat =
                    _filterCategory == null || p.categoryId == _filterCategory;
                return matchQ && matchCat;
              }).toList();

              if (list.isEmpty) return const ProdEmptyState();

              // ignore: unused_local_variable — forces Obx to track maxProducible
              final _ = ctrl.maxProducible.length;

              return ProductTable(
                products: list,
                categories: ctrl.categories,
                units: ctrl.units,
                maxProducible: ctrl.maxProducible,
                onEdit: (p) => _openForm(ctrl, product: p),
                onDelete: (p) => _confirmDelete(context, p),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openForm(ProductsController ctrl, {Product? product}) {
    Get.dialog(
      ProductFormDialog(product: product),
      barrierDismissible: true,
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 60 : 15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(15), shape: BoxShape.circle),
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  color: AppColors.red,
                  size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'prod_delete_title'.tr,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              '"${p.name}" ${'prod_delete_confirm'.tr}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textGrey
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    final auth = Get.find<AuthController>();
                    if (auth.can(Permission.deleteProduct)) {
                      Get.find<ProductsController>().delete(p.id);
                      Get.back();
                    } else {
                      final approved =
                          await auth.requireAdmin('auth_req_delete'.tr);
                      if (approved) {
                        Get.find<ProductsController>().delete(p.id);
                        Get.back();
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
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
                'prod_title'.tr,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Obx(() {
                final count =
                    Get.find<ProductsController>().products.length;
                return Text(
                  '$count ${'prod_count'.tr}',
                  style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textGrey
                          : const Color(0xFF94A3B8)),
                );
              }),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 18,
                color: Colors.white),
            label: Text('prod_add_new'.tr,
                style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final ValueChanged<int?> onCategory;
  final int? selectedCategory;

  const _FilterBar({
    required this.searchCtrl,
    required this.onSearch,
    required this.onCategory,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final hintColor = isDark ? AppColors.textDim : const Color(0xFFB0B8C8);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      color: isDark ? AppColors.bgSurface : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: TextStyle(
                    fontFamily: 'Gilroy', color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'prod_search'.tr,
                  hintStyle: TextStyle(
                      fontFamily: 'Gilroy', color: hintColor, fontSize: 13),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: hintColor,
                        size: 14),
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: hintColor,
                              size: 14),
                          onPressed: () {
                            searchCtrl.clear();
                            onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final cats = Get.find<ProductsController>().categories;
            return SizedBox(
              height: 40,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButton<int?>(
                    value: selectedCategory,
                    dropdownColor:
                        isDark ? AppColors.bgCard : Colors.white,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: textColor,
                        fontSize: 13),
                    icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        color: hintColor,
                        size: 18),
                    items: [
                      DropdownMenuItem(
                          value: null,
                          child: Text('prod_all_cats'.tr)),
                      ...cats.map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name))),
                    ],
                    onChanged: onCategory,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
