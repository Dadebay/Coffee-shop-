import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/ingredients_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

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
            child: Obx(() => ctrl.loading.value
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary2))
                : ctrl.ingredients.isEmpty
                    ? _EmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.4,
                        ),
                        itemCount: ctrl.ingredients.length,
                        itemBuilder: (_, i) => _IngTile(ingredient: ctrl.ingredients[i]),
                      )),
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
                final count = Get.find<IngredientsController>().ingredients.length;
                return Text(
                  '$count ${'ing_count'.tr}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18, color: Colors.white),
            label: Text(
              'ing_add'.tr,
              style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13),
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
            child: HugeIcon(icon: HugeIcons.strokeRoundedWarehouse, size: 40, color: AppColors.primary2),
          ),
          const SizedBox(height: 16),
          Text(
            'ing_empty'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textGrey : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.dialog(const IngredientFormDialog()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary2),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: Colors.white),
            label: Text('ing_add'.tr, style: const TextStyle(fontFamily: 'Gilroy')),
          ),
        ],
      ),
    );
  }
}

class _IngTile extends StatefulWidget {
  final Ingredient ingredient;
  const _IngTile({required this.ingredient});

  @override
  State<_IngTile> createState() => _IngTileState();
}

class _IngTileState extends State<_IngTile> {
  bool _hovered = false;

  bool get _isLow => widget.ingredient.minStock > 0 && widget.ingredient.stock <= widget.ingredient.minStock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ing = widget.ingredient;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = _isLow ? AppColors.red.withAlpha(100) : (_hovered ? AppColors.primary.withAlpha(60) : (isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)));
    final barColor = _isLow ? AppColors.red : AppColors.green;
    final pct = ing.minStock > 0 ? (ing.stock / (ing.minStock * 3)).clamp(0.0, 1.0) : 1.0;
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered && !isDark ? const Color(0xFFF8FAFF) : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : (_hovered ? 8 : 4)),
              blurRadius: _hovered ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: name + badges + actions ──
            Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: barColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ing.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
                if (_isLow)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.red.withAlpha(70)),
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 10, color: AppColors.red),
                  ),
                _SmallIconBtn(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: AppColors.green,
                  onTap: () => Get.dialog(StockAdjustDialog(ingredient: ing)),
                ),
                const SizedBox(width: 2),
                _SmallIconBtn(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  color: AppColors.textGrey,
                  onTap: () => Get.dialog(IngredientFormDialog(ingredient: ing)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Progress bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: isDark ? AppColors.bgBorder : const Color(0xFFEEF2FF),
                color: barColor,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),

            // ── Bottom row: stock value + cost ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatCurrency(ing.cost)} / ${ing.unit}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      color: isDark ? AppColors.textDim : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${ing.stock.toStringAsFixed(1)} ${ing.unit}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: _isLow ? AppColors.red : barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatefulWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hov ? widget.color.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: HugeIcon(icon: widget.icon, size: 14, color: widget.color),
        ),
      ),
    );
  }
}

// ─── Shared dialog shell ──────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final String title;
  final Widget content;
  final double width;
  const _DialogShell({required this.title, required this.content, this.width = 420});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 20),
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
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedWarehouse,
                      size: 18,
                      color: AppColors.primary2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  _CloseX(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Divider(color: borderColor, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseX extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.textGrey),
      ),
    );
  }
}

class _DField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool numeric;
  final String? Function(String?)? validator;
  final String? suffix;

  const _DField({
    required this.controller,
    required this.label,
    this.numeric = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
      validator: validator,
      style: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 14,
        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool loading;
  const _DialogActions({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: Get.back,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: BorderSide(color: Colors.grey.withAlpha(60)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              cancelLabel,
              style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    confirmLabel,
                    style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Ingredient Form Dialog ───────────────────────────────────────────────────

class IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  const IngredientFormDialog({super.key, this.ingredient});

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.ingredient?.name ?? '');
  late final _cost = TextEditingController(text: widget.ingredient?.cost.toStringAsFixed(2) ?? '0');
  late final _stock = TextEditingController(text: widget.ingredient?.stock.toStringAsFixed(2) ?? '0');
  late final _minStock = TextEditingController(text: widget.ingredient?.minStock.toStringAsFixed(2) ?? '0');
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

    return _DialogShell(
      title: isEdit ? 'ing_edit'.tr : 'ing_add'.tr,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DField(
              controller: _name,
              label: 'ing_name'.tr,
              validator: (v) => v?.isEmpty == true ? 'gen_required'.tr : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _UnitDropdown(value: _unit, onChanged: (v) => setState(() => _unit = v), isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _DField(controller: _cost, label: 'ing_cost'.tr, numeric: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DField(controller: _stock, label: 'ing_stock'.tr, numeric: true, suffix: _unit)),
              const SizedBox(width: 12),
              Expanded(child: _DField(controller: _minStock, label: 'ing_min_stock'.tr, numeric: true, suffix: _unit)),
            ]),
            const SizedBox(height: 20),
            _DialogActions(
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
      Get.snackbar('gen_error'.tr, e.toString(), backgroundColor: AppColors.red, colorText: Colors.white);
    }
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  final bool isDark;
  const _UnitDropdown({required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? AppColors.bgCard : Colors.white,
      style: TextStyle(
        fontFamily: 'Gilroy',
        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: 'ing_unit'.tr,
        labelStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: isDark ? AppColors.textGrey : const Color(0xFF64748B)),
        filled: true,
        fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
      ),
      items: const [
        DropdownMenuItem(value: 'g', child: Text('Gram (g)')),
        DropdownMenuItem(value: 'ml', child: Text('Mililitre (ml)')),
        DropdownMenuItem(value: 'pcs', child: Text('Adet (pcs)')),
      ],
      onChanged: (v) => onChanged(v!),
    );
  }
}

// ─── Stock Adjust Dialog ──────────────────────────────────────────────────────

class StockAdjustDialog extends StatefulWidget {
  final Ingredient ingredient;
  const StockAdjustDialog({super.key, required this.ingredient});

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  final _ctrl = TextEditingController();
  String _type = 'add';
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _DialogShell(
      title: 'ing_adjust'.tr,
      width: 360,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current stock info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedWarehouse, size: 16, color: AppColors.primary2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.ingredient.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '${widget.ingredient.stock.toStringAsFixed(2)} ${widget.ingredient.unit}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add / Remove toggle
          Row(
            children: [
              Expanded(child: _TypeBtn(label: 'gen_add'.tr, type: 'add', color: AppColors.green, selected: _type == 'add', onTap: () => setState(() => _type = 'add'))),
              const SizedBox(width: 10),
              Expanded(child: _TypeBtn(label: 'ing_remove'.tr, type: 'remove', color: AppColors.red, selected: _type == 'remove', onTap: () => setState(() => _type = 'remove'))),
            ],
          ),
          const SizedBox(height: 14),

          // Amount input
          _DField(
            controller: _ctrl,
            label: 'rec_qty'.tr,
            numeric: true,
            suffix: widget.ingredient.unit,
          ),
          const SizedBox(height: 20),

          _DialogActions(
            cancelLabel: 'gen_cancel'.tr,
            confirmLabel: _type == 'add' ? 'gen_add'.tr : 'ing_remove'.tr,
            loading: _saving,
            onConfirm: _apply,
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    final val = double.tryParse(_ctrl.text) ?? 0;
    if (val <= 0) return;
    setState(() => _saving = true);
    await Get.find<IngredientsController>().adjustStock(widget.ingredient.id, _type == 'add' ? val : -val);
    Get.back();
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final String type;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.type, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.withAlpha(60),
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: type == 'add' ? HugeIcons.strokeRoundedAddCircle : HugeIcons.strokeRoundedRemoveCircle,
              size: 16,
              color: selected ? color : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? color : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
