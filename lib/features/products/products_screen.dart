import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/products_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/permissions.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';

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
                return const Center(child: CircularProgressIndicator(color: AppColors.primary2));
              }

              final list = ctrl.products.where((p) {
                final matchQ = _query.isEmpty ||
                    p.name.toLowerCase().contains(_query.toLowerCase()) ||
                    p.sku.toLowerCase().contains(_query.toLowerCase());
                final matchCat =
                    _filterCategory == null || p.categoryId == _filterCategory;
                return matchQ && matchCat;
              }).toList();

              if (list.isEmpty) return const _EmptyState();

              return _ProductTable(
                products: list,
                categories: ctrl.categories,
                units: ctrl.units,
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
      barrierDismissible: false,
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
          border: Border.all(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 60 : 15), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.red.withAlpha(15), shape: BoxShape.circle),
              child: const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.red, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'prod_delete_title'.tr,
              style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              '"${p.name}" ${'prod_delete_confirm'.tr}',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 13,
                  color: isDark ? AppColors.textGrey : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.withAlpha(60)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_cancel'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
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
                      final approved = await auth.requireAdmin('auth_req_delete'.tr);
                      if (approved) {
                        Get.find<ProductsController>().delete(p.id);
                        Get.back();
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_delete'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
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
                  fontFamily: 'Gilroy', fontSize: 22, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Obx(() {
                final count = Get.find<ProductsController>().products.length;
                return Text(
                  '$count ${'prod_count'.tr}',
                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 13,
                      color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8)),
                );
              }),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18, color: Colors.white),
            label: Text('prod_add_new'.tr,
                style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14)),
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
                style: TextStyle(fontFamily: 'Gilroy', color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'prod_search'.tr,
                  hintStyle: TextStyle(fontFamily: 'Gilroy', color: hintColor, fontSize: 13),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: hintColor, size: 14),
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: hintColor, size: 14),
                          onPressed: () { searchCtrl.clear(); onSearch(''); },
                        )
                      : null,
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2)),
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
                    dropdownColor: isDark ? AppColors.bgCard : Colors.white,
                    style: TextStyle(fontFamily: 'Gilroy', color: textColor, fontSize: 13),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: hintColor, size: 18),
                    items: [
                      DropdownMenuItem(value: null, child: Text('prod_all_cats'.tr)),
                      ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
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

// ─── Table ────────────────────────────────────────────────────────────────────

class _ProductTable extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;
  final List<Unit> units;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;

  const _ProductTable({
    required this.products,
    required this.categories,
    required this.units,
    required this.onEdit,
    required this.onDelete,
  });

  String _catName(int? id) =>
      id == null ? '—' : categories.firstWhereOrNull((c) => c.id == id)?.name ?? '—';

  String _unitShort(int? id) =>
      id == null ? '' : units.firstWhereOrNull((u) => u.id == id)?.shortName ?? '';

  double _discounted(Product p) {
    if (p.discountType == 'percentage') {
      return (p.price - p.price * p.discount / 100).clamp(0, double.infinity);
    }
    return (p.price - p.discount).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = isDark ? AppColors.bgCard   : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final hoverColor  = isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);
    final headerBg    = isDark ? AppColors.bgSurface : const Color(0xFFF4F6FB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 52),
                  Expanded(flex: 3, child: _TH('prod_name'.tr)),
                  Expanded(flex: 2, child: _TH('prod_category'.tr)),
                  Expanded(flex: 2, child: _TH('prod_price'.tr)),
                  Expanded(flex: 2, child: _TH('prod_cost'.tr)),
                  Expanded(flex: 2, child: _TH('prod_profit'.tr)),
                  Expanded(flex: 1, child: _TH('prod_qty'.tr)),
                  Expanded(flex: 1, child: _TH('gen_status'.tr)),
                  SizedBox(width: 80, child: Center(child: _TH('gen_action'.tr))),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  final discPrice = _discounted(p);
                  final cost = p.useRecipeCost ? p.recipeCalculatedCost : p.purchasePrice;
                  final profit = discPrice - cost;
                  final unit = _unitShort(p.unitId);
                  final isLast = i == products.length - 1;
                  final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
                  final subColor  = isDark ? AppColors.textDim   : const Color(0xFF94A3B8);

                  return Container(
                    decoration: BoxDecoration(
                      border: !isLast ? Border(bottom: BorderSide(color: borderColor, width: 0.5)) : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onEdit(p),
                        borderRadius: isLast
                            ? const BorderRadius.vertical(bottom: Radius.circular(16))
                            : null,
                        hoverColor: hoverColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              _ProductThumb(imagePath: p.imagePath, isDark: isDark),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
                                        overflow: TextOverflow.ellipsis),
                                    Row(
                                      children: [
                                        Text('SKU: ${p.sku}',
                                            style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: subColor)),
                                        if (p.expireDate != null) ...[
                                          const SizedBox(width: 8),
                                          _ExpiryBadge(date: p.expireDate!),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_catName(p.categoryId),
                                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 12,
                                        color: isDark ? AppColors.textGrey : const Color(0xFF64748B))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(formatCurrency(discPrice),
                                        style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary2)),
                                    if (p.discount > 0)
                                      Text(formatCurrency(p.price),
                                          style: TextStyle(fontFamily: 'Gilroy', fontSize: 10, color: subColor, decoration: TextDecoration.lineThrough)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(formatCurrency(cost),
                                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 12,
                                        color: isDark ? AppColors.textGrey : const Color(0xFF64748B))),
                              ),
                              Expanded(flex: 2, child: _ProfitBadge(profit: profit)),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${p.quantity}${unit.isNotEmpty ? ' $unit' : ''}',
                                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600,
                                      color: p.quantity > 0 ? textColor : AppColors.red),
                                ),
                              ),
                              Expanded(flex: 1, child: _StatusBadge(active: p.status)),
                              SizedBox(
                                width: 80,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _IconBtn(icon: HugeIcons.strokeRoundedPencilEdit01, color: AppColors.primary2, onTap: () => onEdit(p)),
                                    const SizedBox(width: 4),
                                    _IconBtn(icon: HugeIcons.strokeRoundedDelete02, color: AppColors.red, onTap: () => onDelete(p)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.textGrey, letterSpacing: 0.5));
}

class _IconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
        child: HugeIcon(icon: icon, size: 15, color: color),
      ),
    );
  }
}

class _ProfitBadge extends StatelessWidget {
  final double profit;
  const _ProfitBadge({required this.profit});

  @override
  Widget build(BuildContext context) {
    final color = profit >= 0 ? AppColors.green : AppColors.red;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          '${profit >= 0 ? '+' : ''}${formatCurrency(profit)}',
          style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (active ? AppColors.green : AppColors.textDim).withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          active ? 'prod_status_active'.tr : 'prod_status_inactive'.tr,
          style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w700,
              color: active ? AppColors.green : AppColors.textDim),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedPackage, size: 54,
              color: isDark ? AppColors.textDim.withAlpha(120) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text('prod_empty'.tr,
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 15,
                  color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ─── Product Thumbnail ────────────────────────────────────────────────────────

class _ProductThumb extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  const _ProductThumb({required this.imagePath, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    final dimColor = isDark ? AppColors.textDim : const Color(0xFFB0B8C8);
    if (imagePath == null || imagePath!.isEmpty) {
      return HugeIcon(icon: HugeIcons.strokeRoundedCoffee01, size: 20, color: dimColor);
    }
    if (kIsWeb || imagePath!.startsWith('data:')) {
      try {
        final comma = imagePath!.indexOf(',');
        if (comma < 0) throw Exception();
        final bytes = base64Decode(imagePath!.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 20, color: dimColor);
      }
    }
    return Image.file(File(imagePath!), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 20, color: dimColor));
  }
}

// ─── Form Dialog ──────────────────────────────────────────────────────────────

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name  = TextEditingController(text: widget.product?.name ?? '');
  late final _sku   = TextEditingController(text: widget.product?.sku ?? '');
  late final _price = TextEditingController(text: widget.product?.price.toStringAsFixed(2) ?? '0');
  late final _cost  = TextEditingController(text: widget.product?.purchasePrice.toStringAsFixed(2) ?? '0');
  late final _disc  = TextEditingController(text: widget.product?.discount.toStringAsFixed(2) ?? '0');
  late final _qty   = TextEditingController(text: widget.product?.quantity.toString() ?? '0');

  String _discType = 'fixed';
  bool _status = true;
  int? _categoryId;
  int? _unitId;
  String? _imagePath;
  DateTime? _expireDate;
  bool _loading = false;

  final _ctrl = Get.find<ProductsController>();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _discType   = p.discountType;
      _status     = p.status;
      _categoryId = p.categoryId;
      _unitId     = p.unitId;
      _imagePath  = p.imagePath;
      _expireDate = p.expireDate;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _price, _cost, _disc, _qty]) { c.dispose(); }
    super.dispose();
  }

  bool get _isEdit => widget.product != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder  : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(isDark ? 120 : 20), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePanel(
              imagePath: _imagePath,
              isDark: isDark,
              onPick: () async {
                final path = await _ctrl.pickImage();
                if (path != null) setState(() => _imagePath = path);
              },
              onRemove: () => setState(() => _imagePath = null),
            ),
            Container(width: 1, color: borderColor),
            Expanded(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogTitle(isEdit: _isEdit, isDark: isDark, borderColor: borderColor),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('prod_basic_info'.tr, isDark),
                            const SizedBox(height: 10),
                            _field(_name, 'prod_name'.tr, isDark: isDark, required: true),
                            const SizedBox(height: 12),
                            _field(_sku, 'prod_sku'.tr, isDark: isDark),
                            const SizedBox(height: 20),
                            _sectionLabel('prod_pricing'.tr, isDark),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _field(_price, 'prod_price'.tr, isDark: isDark, numeric: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_cost, 'prod_cost'.tr, isDark: isDark, numeric: true)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _field(_qty, 'prod_qty'.tr, isDark: isDark, numeric: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _discTypeDropdown(isDark)),
                            ]),
                            const SizedBox(height: 20),
                            _sectionLabel('prod_stock_management'.tr, isDark),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _categoryDropdown(isDark)),
                              const SizedBox(width: 12),
                              Expanded(child: _unitDropdown(isDark)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              SizedBox(width: 160, child: _field(_qty, 'prod_stock_qty'.tr, isDark: isDark, numeric: true)),
                              const SizedBox(width: 12),
                              _StatusToggle(value: _status, onChanged: (v) => setState(() => _status = v), isDark: isDark),
                            ]),
                            const SizedBox(height: 12),
                            _DatePickerField(
                              label: 'exp_title'.tr,
                              value: _expireDate,
                              isDark: isDark,
                              onChanged: (d) => setState(() => _expireDate = d),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    _ActionBar(
                      loading: _loading,
                      isEdit: _isEdit,
                      isDark: isDark,
                      borderColor: borderColor,
                      onCancel: Get.back,
                      onSave: _save,
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

  Widget _sectionLabel(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDim : const Color(0xFF94A3B8),
          letterSpacing: 1));

  Widget _field(TextEditingController c, String label,
      {required bool isDark, bool required = false, bool numeric = false}) {
    return TextFormField(
      controller: c,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
      style: TextStyle(fontFamily: 'Gilroy',
          color: isDark ? AppColors.textWhite : const Color(0xFF0F172A), fontSize: 13),
      decoration: _inputDecoration(label, isDark),
      validator: required ? (v) => v?.trim().isEmpty == true ? 'gen_required'.tr : null : null,
    );
  }

  Widget _discTypeDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _discType,
      dropdownColor: isDark ? AppColors.bgCard : Colors.white,
      style: TextStyle(fontFamily: 'Gilroy',
          color: isDark ? AppColors.textWhite : const Color(0xFF0F172A), fontSize: 13),
      decoration: _inputDecoration('prod_disc_type'.tr, isDark),
      items: [
        DropdownMenuItem(value: 'fixed',      child: Text('prod_disc_fixed'.tr)),
        DropdownMenuItem(value: 'percentage', child: Text('prod_disc_perc'.tr)),
      ],
      onChanged: (v) => setState(() => _discType = v!),
    );
  }

  Widget _categoryDropdown(bool isDark) {
    return Obx(() => DropdownButtonFormField<int?>(
          value: _categoryId,
          dropdownColor: isDark ? AppColors.bgCard : Colors.white,
          style: TextStyle(fontFamily: 'Gilroy',
              color: isDark ? AppColors.textWhite : const Color(0xFF0F172A), fontSize: 13),
          decoration: _inputDecoration('prod_category'.tr, isDark),
          items: [
            DropdownMenuItem(value: null, child: Text('prod_select'.tr)),
            ..._ctrl.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ));
  }

  Widget _unitDropdown(bool isDark) {
    return Obx(() => DropdownButtonFormField<int?>(
          value: _unitId,
          dropdownColor: isDark ? AppColors.bgCard : Colors.white,
          style: TextStyle(fontFamily: 'Gilroy',
              color: isDark ? AppColors.textWhite : const Color(0xFF0F172A), fontSize: 13),
          decoration: _inputDecoration('prod_unit'.tr, isDark),
          items: [
            DropdownMenuItem(value: null, child: Text('prod_select'.tr)),
            ..._ctrl.units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
          ],
          onChanged: (v) => setState(() => _unitId = v),
        ));
  }

  InputDecoration _inputDecoration(String label, bool isDark) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Gilroy',
            color: isDark ? AppColors.textGrey : const Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.red)),
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    
    final newPrice = double.tryParse(_price.text) ?? 0;
    if (_isEdit && widget.product != null && widget.product!.price != newPrice) {
      final auth = Get.find<AuthController>();
      if (!auth.can(Permission.changePrice)) {
        final approved = await auth.requireAdmin('auth_req_price'.tr);
        if (!approved) return;
      }
    }

    setState(() => _loading = true);
    try {
      await _ctrl.save(
        existing: widget.product,
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        price: double.tryParse(_price.text) ?? 0,
        purchasePrice: double.tryParse(_cost.text) ?? 0,
        discount: double.tryParse(_disc.text) ?? 0,
        discountType: _discType,
        quantity: int.tryParse(_qty.text) ?? 0,
        categoryId: _categoryId,
        unitId: _unitId,
        imagePath: _imagePath,
        expireDate: _expireDate,
      );
      Get.back();
      Get.snackbar(
        _isEdit ? 'gen_updated'.tr : 'gen_added'.tr,
        '"${_name.text.trim()}" ${_isEdit ? 'gen_updated_msg'.tr : 'gen_added_msg'.tr}.',
        backgroundColor: AppColors.green.withAlpha(220),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('gen_error'.tr, e.toString(),
          backgroundColor: AppColors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16), borderRadius: 10);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Image Panel ──────────────────────────────────────────────────────────────

class _ImagePanel extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePanel({required this.imagePath, required this.isDark, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final fillColor   = isDark ? AppColors.bgCard   : const Color(0xFFF4F6FB);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor   = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final dimColor    = isDark ? AppColors.textDim  : const Color(0xFFB0B8C8);

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text('prod_photo'.tr,
                style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: onPick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 200,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: imagePath != null ? AppColors.primary2.withAlpha(80) : borderColor,
                    width: imagePath != null ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null
                    ? Stack(fit: StackFit.expand, children: [
                        _buildPreview(imagePath!),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withAlpha(160)],
                              ),
                            ),
                            child: Center(
                              child: Text('gen_change'.tr,
                                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(color: AppColors.primary2.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, size: 26, color: AppColors.primary2),
                          ),
                          const SizedBox(height: 12),
                          Text('gen_photo_select'.tr,
                              style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 4),
                          Text('gen_formats'.tr,
                              style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: dimColor)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: onPick,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary2,
                    side: const BorderSide(color: AppColors.primary2, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedUpload01, size: 16, color: AppColors.primary2),
                  label: Text('gen_upload'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (imagePath != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: AppColors.red),
                    label: Text('gen_remove'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 13, color: dimColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('gen_max_file'.tr,
                        style: TextStyle(fontFamily: 'Gilroy', fontSize: 10, color: dimColor, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String path) {
    final dimColor = isDark ? AppColors.textDim : const Color(0xFFB0B8C8);
    if (kIsWeb || path.startsWith('data:')) {
      try {
        final comma = path.indexOf(',');
        if (comma < 0) throw Exception();
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 32, color: dimColor);
      }
    }
    return Image.file(File(path), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 32, color: dimColor));
  }
}

// ─── Dialog Title ─────────────────────────────────────────────────────────────

class _DialogTitle extends StatelessWidget {
  final bool isEdit;
  final bool isDark;
  final Color borderColor;
  const _DialogTitle({required this.isEdit, required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: AppColors.primary2, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Text(
            isEdit ? 'prod_edit'.tr : 'prod_add'.tr,
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(
            onPressed: Get.back,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.textGrey, size: 20),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Status Toggle ────────────────────────────────────────────────────────────

class _StatusToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  const _StatusToggle({required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? AppColors.green.withAlpha(80)
                : (isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: value ? AppColors.green : AppColors.textDim,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value ? 'prod_status_active'.tr : 'prod_status_inactive'.tr,
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600,
                  color: value ? AppColors.green : AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool loading;
  final bool isEdit;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _ActionBar({
    required this.loading, required this.isEdit,
    required this.isDark, required this.borderColor,
    required this.onCancel, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: loading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textGrey,
              side: BorderSide(color: Colors.grey.withAlpha(60)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text('gen_cancel'.tr, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              disabledBackgroundColor: AppColors.primary2.withAlpha(80),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'set_update'.tr : 'gen_save'.tr,
                    style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Expiry Helpers (Feature 5) ─────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool isDark;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final bgColor = isDark ? AppColors.bgCard : const Color(0xFFF8FAFF);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontFamily: 'Gilroy',
              color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
              fontSize: 12),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
                        : 'prod_select_date'.tr,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: value != null ? textColor : AppColors.textGrey,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.textGrey, size: 16),
                  )
                else
                  const HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: AppColors.textGrey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final DateTime date;
  const _ExpiryBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = date.isBefore(now);
    final isExpiringSoon = !isExpired && date.isBefore(now.add(const Duration(days: 7)));
    
    if (!isExpired && !isExpiringSoon) return const SizedBox.shrink(); // No badge if safe

    final color = isExpired ? AppColors.red : AppColors.orange;
    final text = isExpired ? 'exp_expired'.tr : 'exp_warning'.tr.replaceAll('{days}', date.difference(now).inDays.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 50 : 20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
