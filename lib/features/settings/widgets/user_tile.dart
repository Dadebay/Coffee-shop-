import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';

// ── User tile ─────────────────────────────────────────────────────────────────
class UserTile extends StatefulWidget {
  final User user;
  final VoidCallback onEdit;
  const UserTile({super.key, required this.user, required this.onEdit});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final isAdmin = widget.user.role == 'admin';
    final roleColor = isAdmin ? AppColors.primary2 : AppColors.blue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.bgCard : const Color(0xFFF8FAFF))
              : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? AppColors.primary.withAlpha(60) : borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_hovered ? 10 : 5),
              blurRadius: _hovered ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: roleColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withAlpha(50)),
              ),
              child: Center(
                child: HugeIcon(
                  icon: isAdmin
                      ? HugeIcons.strokeRoundedShieldUser
                      : HugeIcons.strokeRoundedUser,
                  color: roleColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      UserMetaChip(
                        label: 'PIN: ${widget.user.pin}',
                        hugeIcon: HugeIcons.strokeRoundedLock,
                      ),
                      const SizedBox(width: 6),
                      UserMetaChip(
                        label: isAdmin
                            ? 'set_role_admin'.tr
                            : 'set_role_cashier'.tr,
                        hugeIcon: isAdmin
                            ? HugeIcons.strokeRoundedShield02
                            : HugeIcons.strokeRoundedCashier,
                        color: roleColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            UserStatusBadge(active: widget.user.isActive),
            const SizedBox(width: 10),
            UserEditBtn(onTap: widget.onEdit),
          ],
        ),
      ),
    );
  }
}

// ── User meta chip ────────────────────────────────────────────────────────────
class UserMetaChip extends StatelessWidget {
  final String label;
  final dynamic hugeIcon;
  final Color? color;
  const UserMetaChip(
      {super.key, required this.label, required this.hugeIcon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textGrey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: hugeIcon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(label,
            style:
                TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: c)),
      ],
    );
  }
}

// ── User status badge ─────────────────────────────────────────────────────────
class UserStatusBadge extends StatelessWidget {
  final bool active;
  const UserStatusBadge({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            active ? 'prod_status_active'.tr : 'prod_status_inactive'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── User edit button ──────────────────────────────────────────────────────────
class UserEditBtn extends StatefulWidget {
  final VoidCallback onTap;
  const UserEditBtn({super.key, required this.onTap});

  @override
  State<UserEditBtn> createState() => _UserEditBtnState();
}

class _UserEditBtnState extends State<UserEditBtn> {
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
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hov
                ? AppColors.primary.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hov
                  ? AppColors.primary.withAlpha(60)
                  : Colors.grey.withAlpha(40),
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit01,
              size: 16,
              color: _hov ? AppColors.primary2 : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}

