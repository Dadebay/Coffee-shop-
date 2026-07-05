import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/ingredients_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import 'ing_shared.dart';

class IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  const IngredientFormDialog({super.key, this.ingredient});

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.ingredient?.name ?? '');
  late final _cost = TextEditingController(
      text: widget.ingredient?.cost.toStringAsFixed(2) ?? '0');
  late final _stock = TextEditingController(
      text: widget.ingredient?.stock.toStringAsFixed(2) ?? '0');
  late final _minStock = TextEditingController(
      text: widget.ingredient?.minStock.toStringAsFixed(2) ?? '0');
  String _unit = 'g';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unit = widget.ingredient?.unit ?? 'g';
  }

  @override
  void dispose() {
    for (final c in [_name, _cost, _stock, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ingredient != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IngDialogShell(
      title: isEdit ? 'ing_edit'.tr : 'ing_add'.tr,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IngField(
              controller: _name,
              label: 'ing_name'.tr,
              validator: (v) =>
                  v?.isEmpty == true ? 'gen_required'.tr : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _UnitDropdown(
                      value: _unit,
                      onChanged: (v) => setState(() => _unit = v),
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: IngField(
                      controller: _cost,
                      label: 'ing_cost'.tr,
                      numeric: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: IngField(
                      controller: _stock,
                      label: 'ing_stock'.tr,
                      numeric: true,
                      suffix: _unit)),
              const SizedBox(width: 12),
              Expanded(
                  child: IngField(
                      controller: _minStock,
                      label: 'ing_min_stock'.tr,
                      numeric: true,
                      suffix: _unit)),
            ]),
            const SizedBox(height: 20),
            IngDialogActions(
              cancelLabel: 'gen_cancel'.tr,
              confirmLabel: isEdit ? 'gen_save'.tr : 'gen_add'.tr,
              loading: _saving,
              onConfirm: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Get.find<IngredientsController>().save(
        existing: widget.ingredient,
        name: _name.text.trim(),
        unit: _unit,
        cost: double.tryParse(_cost.text) ?? 0,
        stock: double.tryParse(_stock.text) ?? 0,
        minStock: double.tryParse(_minStock.text) ?? 0,
      );
      Get.back();
    } catch (e) {
      setState(() => _saving = false);
      Get.snackbar('gen_error'.tr, e.toString(),
          backgroundColor: AppColors.red, colorText: Colors.white);
    }
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  final bool isDark;
  const _UnitDropdown(
      {required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: isDark ? AppColors.bgCard : Colors.white,
      style: TextStyle(
        fontFamily: 'Gilroy',
        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: 'ing_unit'.tr,
        labelStyle: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            color:
                isDark ? AppColors.textGrey : const Color(0xFF64748B)),
        filled: true,
        fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? AppColors.bgBorder
                    : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? AppColors.bgBorder
                    : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary2, width: 1.5)),
      ),
      items: [
        DropdownMenuItem(value: 'g', child: Text('ing_unit_g'.tr)),
        DropdownMenuItem(value: 'ml', child: Text('ing_unit_ml'.tr)),
        DropdownMenuItem(value: 'pcs', child: Text('ing_unit_pcs'.tr)),
      ],
      onChanged: (v) => onChanged(v!),
    );
  }
}
