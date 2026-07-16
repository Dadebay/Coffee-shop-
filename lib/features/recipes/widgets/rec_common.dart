import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/product_thumb.dart';

// ── Empty right panel ─────────────────────────────────────────────────────────
class RecEmptyRight extends StatelessWidget {
  final bool isDark;
  const RecEmptyRight({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBook02,
                  size: 34,
                  color: AppColors.primary2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'rec_select_left'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'rec_select_product'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              color: isDark ? AppColors.textDim : const Color(0xFFB0BAC9),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────
class RecProductTile extends StatefulWidget {
  final Product product;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const RecProductTile(
      {super.key,
      required this.product,
      required this.selected,
      required this.isDark,
      required this.onTap});

  @override
  State<RecProductTile> createState() => _RecProductTileState();
}

class _RecProductTileState extends State<RecProductTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final sel = widget.selected;
    final isDark = widget.isDark;

    final hoverColor = isDark ? AppColors.bgCard : const Color(0xFFF0F4FF);
    final bg = sel
        ? AppColors.primary2
        : _hovered
            ? hoverColor
            : hoverColor.withAlpha(0);

    final textColor = sel
        ? Colors.white
        : (isDark ? AppColors.textWhite : const Color(0xFF0F172A));

    final subColor = sel ? Colors.white.withAlpha(180) : AppColors.textGrey;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: AppColors.primary2.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Row(
            children: [
              ProductThumb(
                imagePath: p.imagePath,
                isDark: isDark,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatCurrency(p.price),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (sel)
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 16,
                    color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Icon button ───────────────────────────────────────────────────────────────
class RecIconBtn extends StatefulWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const RecIconBtn(
      {super.key,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  State<RecIconBtn> createState() => _RecIconBtnState();
}

class _RecIconBtnState extends State<RecIconBtn> {
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hov ? widget.color.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: HugeIcon(icon: widget.icon, size: 15, color: widget.color),
        ),
      ),
    );
  }
}

// ── Stat badge ────────────────────────────────────────────────────────────────
class RecStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final List<List<dynamic>> icon;
  final bool isDark;

  const RecStatBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(35) : color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withAlpha(isDark ? 100 : 80), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 60 : 35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: HugeIcon(icon: icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: color.withAlpha(isDark ? 200 : 170),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
