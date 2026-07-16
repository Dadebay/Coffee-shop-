import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import 'rec_common.dart';

// ── Recipe row ────────────────────────────────────────────────────────────────
class RecipeRow extends StatefulWidget {
  final Recipe recipe;
  final Ingredient ingredient;
  final double lineCost;
  final bool isDark;
  final Color cardColor, borderColor, textColor;
  final VoidCallback onEdit, onDelete;

  const RecipeRow({
    super.key,
    required this.recipe,
    required this.ingredient,
    required this.lineCost,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<RecipeRow> createState() => _RecipeRowState();
}

class _RecipeRowState extends State<RecipeRow> {
  bool _hov = false;

  String _fmtQty(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final r = widget.recipe;

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _hov
              ? (widget.isDark
                  ? AppColors.bgCard.withAlpha(200)
                  : const Color(0xFFF8FAFF))
              : widget.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  _hov ? AppColors.primary.withAlpha(40) : widget.borderColor),
          boxShadow: widget.isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withAlpha(_hov ? 8 : 4),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: AppColors.primary2.withAlpha(160),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(ing.name,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: widget.textColor)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${_fmtQty(ing.stock)} ${ing.unit}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: ing.stock <= ing.minStock
                        ? AppColors.red
                        : (widget.isDark
                            ? AppColors.textGrey
                            : const Color(0xFF64748B)),
                    fontWeight: ing.stock <= ing.minStock
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${_fmtQty(r.quantity)} ${ing.unit}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: widget.isDark
                        ? AppColors.textGrey
                        : const Color(0xFF64748B),
                    fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${formatCurrency(ing.cost)}/${ing.unit}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: widget.isDark
                        ? AppColors.textGrey
                        : const Color(0xFF94A3B8),
                    fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary2.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatCurrency(widget.lineCost),
                    style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.primary2,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 68,
              child: Row(
                children: [
                  RecIconBtn(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      color: AppColors.textGrey,
                      onTap: widget.onEdit),
                  const SizedBox(width: 4),
                  RecIconBtn(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: AppColors.red,
                      onTap: widget.onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

