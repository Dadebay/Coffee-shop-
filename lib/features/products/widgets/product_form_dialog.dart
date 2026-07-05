import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/products_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/permissions.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';

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
  late final _sku = TextEditingController(text: widget.product?.sku ?? '');
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
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _price, _disc, _qty]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.product != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

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
                            _sectionLabel('prod_pricing'.tr, isDark),
                            const SizedBox(height: 10),
                            _field(_price, 'prod_price'.tr,
                                isDark: isDark, numeric: true),
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
      {required bool isDark, bool required = false, bool numeric = false}) {
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
      await _ctrl.save(
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
