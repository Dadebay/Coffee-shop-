import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/ingredients_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import 'ing_shared.dart';

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

    return IngDialogShell(
      title: 'ing_adjust'.tr,
      width: 360,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedWarehouse,
                    size: 16,
                    color: AppColors.primary2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.ingredient.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
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
          Row(
            children: [
              Expanded(
                  child: _TypeBtn(
                      label: 'gen_add'.tr,
                      type: 'add',
                      color: AppColors.green,
                      selected: _type == 'add',
                      onTap: () => setState(() => _type = 'add'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _TypeBtn(
                      label: 'ing_remove'.tr,
                      type: 'remove',
                      color: AppColors.red,
                      selected: _type == 'remove',
                      onTap: () => setState(() => _type = 'remove'))),
            ],
          ),
          const SizedBox(height: 14),
          IngField(
            controller: _ctrl,
            label: 'rec_qty'.tr,
            numeric: true,
            suffix: widget.ingredient.unit,
          ),
          const SizedBox(height: 20),
          IngDialogActions(
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
    await Get.find<IngredientsController>()
        .adjustStock(widget.ingredient.id, _type == 'add' ? val : -val);
    Get.back();
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final String type;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.type,
      required this.color,
      required this.selected,
      required this.onTap});

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
              icon: type == 'add'
                  ? HugeIcons.strokeRoundedAddCircle
                  : HugeIcons.strokeRoundedRemoveCircle,
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
