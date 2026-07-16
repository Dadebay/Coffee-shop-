import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/color_constants.dart';

// ── Tab button ─────────────────────────────────────────────────────────────────

class RepTabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final List<List<dynamic>>? icon;

  const RepTabButton({
    super.key,
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary2
              : (isDark ? AppColors.bgCard : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(
                  icon: icon!,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.textGrey),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isActive
                      ? Colors.white
                      : (isDark ? AppColors.textGrey : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Big stat card ──────────────────────────────────────────────────────────────

class RepBigStatCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const RepBigStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Center(child: HugeIcon(icon: icon, color: color, size: 22)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textGrey
                            : const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

