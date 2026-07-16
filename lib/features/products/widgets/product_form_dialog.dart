import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/products_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/database_controller.dart';
import '../../../core/permissions.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

// ─── Form Dialog ──────────────────────────────────────────────────────────────

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _sku = TextEditingController(
      text: widget.product?.sku ?? _generateDefaultSku());
  late final _price = TextEditingController(
      text: widget.product?.price.toStringAsFixed(2) ?? '0');
  late final _disc = TextEditingController(
      text: widget.product?.discount.toStringAsFixed(2) ?? '0');
  late final _qty =
      TextEditingController(text: widget.product?.quantity.toString() ?? '0');

  String _discType = 'fixed';
  bool _status = true;
  int? _categoryId;
  int? _unitId;
  String? _imagePath;
  DateTime? _expireDate;
  bool _loading = false;

  final _ctrl = Get.find<ProductsController>();
  final _db = Get.find<DatabaseController>().db;

  List<Ingredient> _allIngredients = [];
  final List<_RecipeRowData> _recipeRows = [];
  bool _loadingIngredients = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _discType = p.discountType;
      _status = p.status;
      _categoryId = p.categoryId;
      _unitId = p.unitId;
      _imagePath = p.imagePath;
      _expireDate = p.expireDate;
    }
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await _db.getAllIngredients();
    final existing = widget.product != null
        ? await _db.getRecipesForProduct(widget.product!.id)
        : <Recipe>[];
    if (!mounted) return;
    setState(() {
      _allIngredients = ingredients;
      _recipeRows.addAll(existing.map((r) => _RecipeRowData(
            ingredientId: r.ingredientId,
            qtyCtrl: TextEditingController(text: _fmtQty(r.quantity)),
          )));
      _loadingIngredients = false;
    });
  }

  // Matches the fallback ProductsController.save() would generate anyway if
  // left empty — shown upfront so the user sees what will be saved.
  static String _generateDefaultSku() =>
      'SKU-${DateTime.now().millisecondsSinceEpoch}';

  String _fmtQty(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _price, _disc, _qty]) {
      c.dispose();
    }
    for (final row in _recipeRows) {
      row.qtyCtrl.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.product != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    // The recipe + pricing sections make this dialog taller than most forms
    // — grow with the window instead of clipping content at a fixed height.
    final maxDialogHeight =
        (MediaQuery.of(context).size.height - 40).clamp(400.0, 860.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Container(
        width: 820,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 120 : 20),
                blurRadius: 40,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductImagePanel(
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
                    ProductDialogTitle(
                        isEdit: _isEdit,
                        isDark: isDark,
                        borderColor: borderColor),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('prod_basic_info'.tr, isDark),
                            const SizedBox(height: 10),
                            _field(_name, 'prod_name'.tr,
                                isDark: isDark, required: true),
                            const SizedBox(height: 12),
                            _field(_sku, 'prod_sku'.tr, isDark: isDark),
                            const SizedBox(height: 20),
                            _sectionLabel('prod_stock_management'.tr, isDark),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _categoryDropdown(isDark)),
                              const SizedBox(width: 12),
                              ProductStatusToggle(
                                  value: _status,
                                  onChanged: (v) => setState(() => _status = v),
                                  isDark: isDark),
                            ]),
                            const SizedBox(height: 12),
                            ProductDatePickerField(
                              label: 'exp_title'.tr,
                              value: _expireDate,
                              isDark: isDark,
                              onChanged: (d) => setState(() => _expireDate = d),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('nav_recipes'.tr, isDark),
                            const SizedBox(height: 10),
                            _buildRecipeSection(isDark),
                            const SizedBox(height: 20),
                            _sectionLabel('prod_pricing'.tr, isDark),
                            const SizedBox(height: 10),
                            _buildPricingRow(isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    ProductActionBar(
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
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDim : const Color(0xFF94A3B8),
          letterSpacing: 1));

  Widget _field(TextEditingController c, String label,
      {required bool isDark,
      bool required = false,
      bool numeric = false,
      ValueChanged<String>? onChanged}) {
    final style = TextStyle(
        fontFamily: 'Gilroy',
        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
        fontSize: 13);
    final validator = required
        ? (String? v) => v?.trim().isEmpty == true ? 'gen_required'.tr : null
        : null;
    return TextFormField(
      controller: c,
      style: style,
      decoration: _inputDecoration(label, isDark),
      validator: validator,
      onChanged: onChanged,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
    );
  }

  Widget _categoryDropdown(bool isDark) {
    return Obx(() => DropdownButtonFormField<int?>(
          initialValue: _categoryId,
          dropdownColor: isDark ? AppColors.bgCard : Colors.white,
          style: TextStyle(
              fontFamily: 'Gilroy',
              color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
              fontSize: 13),
          decoration: _inputDecoration('prod_category'.tr, isDark),
          items: [
            DropdownMenuItem(value: null, child: Text('prod_select'.tr)),
            ..._ctrl.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ));
  }

  // ── Recipe / ingredients ─────────────────────────────────────────────────

  Widget _buildRecipeSection(bool isDark) {
    if (_loadingIngredients) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_allIngredients.isEmpty) {
      return Text('rec_no_ingredients'.tr,
          style: const TextStyle(
              fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _recipeRows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _recipeRow(i, isDark),
          ),
        OutlinedButton.icon(
          onPressed: _canAddRow ? _addRecipeRow : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary2,
            side: const BorderSide(color: AppColors.primary2, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9)),
          ),
          icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 15,
              color: AppColors.primary2),
          label: Text(
            _canAddRow ? 'rec_add_ingredient'.tr : 'rec_all_added'.tr,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
          ),
        ),
      ],
    );
  }

  bool get _canAddRow => _recipeRows.length < _allIngredients.length;

  void _addRecipeRow() {
    setState(() {
      _recipeRows.add(_RecipeRowData(qtyCtrl: TextEditingController()));
    });
  }

  void _removeRecipeRow(int index) {
    setState(() {
      _recipeRows.removeAt(index).qtyCtrl.dispose();
    });
  }

  Widget _recipeRow(int index, bool isDark) {
    final row = _recipeRows[index];
    final usedElsewhere = _recipeRows
        .where((r) => r != row)
        .map((r) => r.ingredientId)
        .toSet();
    final ing = _allIngredients.firstWhereOrNull((i) => i.id == row.ingredientId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int?>(
            initialValue: row.ingredientId,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.bgCard : Colors.white,
            style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                fontSize: 13),
            decoration: _inputDecoration('rec_ingredient'.tr, isDark),
            items: _allIngredients
                .where((i) => i.id == row.ingredientId || !usedElsewhere.contains(i.id))
                .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                .toList(),
            onChanged: (v) => setState(() => row.ingredientId = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: row.qtyCtrl,
            style: TextStyle(
                fontFamily: 'Gilroy',
                color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                fontSize: 13),
            decoration: _inputDecoration(
                '${'rec_qty'.tr}${ing != null ? ' (${ing.unit})' : ''}', isDark),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            onPressed: () => _removeRecipeRow(index),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 16,
                color: AppColors.red),
            splashRadius: 16,
          ),
        ),
      ],
    );
  }

  // ── Pricing ───────────────────────────────────────────────────────────────

  /// Live sum of ingredient.cost × quantity across the current recipe rows —
  /// a client-side preview of what recalculateAndSaveRecipeCost will persist.
  double get _recipeCost {
    double sum = 0;
    for (final row in _recipeRows) {
      final ing = _allIngredients.firstWhereOrNull((i) => i.id == row.ingredientId);
      if (ing == null) continue;
      final qty = double.tryParse(row.qtyCtrl.text) ?? 0;
      sum += ing.cost * qty;
    }
    return sum;
  }

  Widget _buildPricingRow(bool isDark) {
    final cost = _recipeCost;
    final price = double.tryParse(_price.text) ?? 0;
    final profit = price - cost;
    final valueColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _pricingBox(
            'prod_price'.tr,
            isDark,
            child: TextField(
              controller: _price,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pricingBox('rec_cost'.tr, isDark,
              child: _pricingValue(formatCurrency(cost), AppColors.red)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pricingBox('prod_profit'.tr, isDark,
              child: _pricingValue(formatCurrency(profit),
                  profit >= 0 ? AppColors.green : AppColors.red)),
        ),
      ],
    );
  }

  Widget _pricingValue(String text, Color color) => Text(text,
      style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color));

  /// Shared frame for all three pricing columns so the editable price field
  /// and the two computed (cost/profit) values look like one consistent set
  /// instead of a Material text field next to plain boxes.
  Widget _pricingBox(String label, bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color:
                      isDark ? AppColors.textGrey : const Color(0xFF64748B))),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontFamily: 'Gilroy',
            color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
            fontSize: 12),
        filled: true,
        fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary2, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.red)),
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final newPrice = double.tryParse(_price.text) ?? 0;
    if (_isEdit &&
        widget.product != null &&
        widget.product!.price != newPrice) {
      final auth = Get.find<AuthController>();
      if (!auth.can(Permission.changePrice)) {
        final approved = await auth.requireAdmin('auth_req_price'.tr);
        if (!approved) return;
      }
    }

    setState(() => _loading = true);
    try {
      final productId = await _ctrl.save(
        existing: widget.product,
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        price: double.tryParse(_price.text) ?? 0,
        purchasePrice: 0,
        discount: double.tryParse(_disc.text) ?? 0,
        discountType: _discType,
        quantity: int.tryParse(_qty.text) ?? 0,
        categoryId: _categoryId,
        unitId: _unitId,
        imagePath: _imagePath,
        expireDate: _expireDate,
      );
      await _saveRecipeRows(productId);
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
          backgroundColor: AppColors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 10);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Replaces the product's recipe with the current rows. Simpler and just
  /// as correct as diffing, since recipe rows carry no identity of their own.
  Future<void> _saveRecipeRows(int productId) async {
    await _db.deleteRecipesForProduct(productId);
    var any = false;
    for (final row in _recipeRows) {
      final qty = double.tryParse(row.qtyCtrl.text) ?? 0;
      if (row.ingredientId == null || qty <= 0) continue;
      await _db.createRecipe(RecipesCompanion.insert(
        productId: productId,
        ingredientId: row.ingredientId!,
        quantity: qty,
      ));
      any = true;
    }
    if (any) {
      await _db.recalculateAndSaveRecipeCost(productId);
    }
    await _ctrl.loadAll();
  }
}

class _RecipeRowData {
  int? ingredientId;
  final TextEditingController qtyCtrl;
  _RecipeRowData({this.ingredientId, required this.qtyCtrl});
}

// ─── Image Panel ──────────────────────────────────────────────────────────────

class ProductImagePanel extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const ProductImagePanel(
      {super.key,
      required this.imagePath,
      required this.isDark,
      required this.onPick,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark ? AppColors.bgCard : const Color(0xFFF4F6FB);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final dimColor = isDark ? AppColors.textDim : const Color(0xFFB0B8C8);

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text('prod_photo'.tr,
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
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
                    color: imagePath != null
                        ? AppColors.primary2.withAlpha(80)
                        : borderColor,
                    width: imagePath != null ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null
                    ? Stack(fit: StackFit.expand, children: [
                        _buildPreview(imagePath!),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(160)
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text('gen_change'.tr,
                                  style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: AppColors.primary2.withAlpha(20),
                                borderRadius: BorderRadius.circular(12)),
                            child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedImageAdd01,
                                size: 26,
                                color: AppColors.primary2),
                          ),
                          const SizedBox(height: 12),
                          Text('gen_photo_select'.tr,
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                          const SizedBox(height: 4),
                          Text('gen_formats'.tr,
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: dimColor)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedUpload01,
                      size: 16,
                      color: AppColors.primary2),
                  label: Text('gen_upload'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                if (imagePath != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 16,
                        color: AppColors.red),
                    label: Text('gen_remove'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 13,
                      color: dimColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('gen_max_file'.tr,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 10,
                            color: dimColor,
                            height: 1.5)),
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
        return HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            size: 32,
            color: dimColor);
      }
    }
    return Image.file(File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            size: 32,
            color: dimColor));
  }
}

// ─── Dialog Title ─────────────────────────────────────────────────────────────

class ProductDialogTitle extends StatelessWidget {
  final bool isEdit;
  final bool isDark;
  final Color borderColor;
  const ProductDialogTitle(
      {super.key,
      required this.isEdit,
      required this.isDark,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: AppColors.primary2,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Text(
            isEdit ? 'prod_edit'.tr : 'prod_add'.tr,
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(
            onPressed: Get.back,
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: AppColors.textGrey,
                size: 20),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Status Toggle ────────────────────────────────────────────────────────────

class ProductStatusToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  const ProductStatusToggle(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.isDark});

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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: value ? AppColors.green : AppColors.textDim,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value ? 'prod_status_active'.tr : 'prod_status_inactive'.tr,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value ? AppColors.green : AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────────────────

class ProductActionBar extends StatelessWidget {
  final bool loading;
  final bool isEdit;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const ProductActionBar({
    super.key,
    required this.loading,
    required this.isEdit,
    required this.isDark,
    required this.borderColor,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: loading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textGrey,
              side: BorderSide(color: Colors.grey.withAlpha(60)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            child: Text('gen_cancel'.tr,
                style: const TextStyle(
                    fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              disabledBackgroundColor: AppColors.primary2.withAlpha(80),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'set_update'.tr : 'gen_save'.tr,
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

// ─── Date Picker Field ────────────────────────────────────────────────────────

class ProductDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool isDark;
  final ValueChanged<DateTime?> onChanged;

  const ProductDatePickerField({
    super.key,
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
              initialDate:
                  value ?? DateTime.now().add(const Duration(days: 30)),
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
                    child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: AppColors.textGrey,
                        size: 16),
                  )
                else
                  const HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: AppColors.textGrey,
                      size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
