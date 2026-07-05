import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import 'ingredient_form_dialog.dart';

class IngredientTile extends StatefulWidget {
  final Ingredient ingredient;
  final VoidCallback? onTap;
  final bool selected;
  const IngredientTile(
      {super.key, required this.ingredient, this.onTap, this.selected = false});

  @override
  State<IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<IngredientTile> {
  bool _hovered = false;

  bool get _isLow =>
      widget.ingredient.minStock > 0 &&
      widget.ingredient.stock <= widget.ingredient.minStock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ing = widget.ingredient;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = widget.selected
        ? AppColors.primary2
        : _isLow
            ? AppColors.red.withAlpha(100)
            : (_hovered
                ? AppColors.primary.withAlpha(60)
                : (isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)));
    final barColor = _isLow ? AppColors.red : AppColors.green;
    final pct = ing.minStock > 0
        ? (ing.stock / (ing.minStock * 3)).clamp(0.0, 1.0)
        : 1.0;
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
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
              // ── Top row: name + low badge + edit button ──
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: barColor, shape: BoxShape.circle),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.red.withAlpha(70)),
                      ),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedAlert02,
                          size: 10,
                          color: AppColors.red),
                    ),
                  _SmallIconBtn(
                    icon: HugeIcons.strokeRoundedPencilEdit01,
                    color: AppColors.textGrey,
                    onTap: () =>
                        Get.dialog(IngredientFormDialog(ingredient: ing)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor:
                      isDark ? AppColors.bgBorder : const Color(0xFFEEF2FF),
                  color: barColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),

              // ── Bottom row: cost + stock ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatCurrency(ing.cost)} / ${ing.unit}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${ing.stock.toStringAsFixed(0)} ${ing.unit}',
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
      ),
    );
  }
}

class _SmallIconBtn extends StatefulWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn(
      {required this.icon, required this.color, required this.onTap});

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
