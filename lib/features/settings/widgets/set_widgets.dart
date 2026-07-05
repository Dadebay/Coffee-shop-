import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../controllers/database_controller.dart';
import '../../../controllers/products_controller.dart';
import '../../../core/constants/color_constants.dart';

// ── Category card ─────────────────────────────────────────────────────────────
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key});

  static const _palette = [
    '#E8724A',
    '#187bff',
    '#3ead2c',
    '#fedb00',
    '#FF3B30',
    '#9B59B6',
    '#1ABC9C',
    '#E67E22',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    final ctrl = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());

    return Obx(() {
      final cats = ctrl.categories;

      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            ...cats.asMap().entries.map((e) {
              final cat = e.value;
              final color = _hexColor(cat.color);
              return Container(
                decoration: BoxDecoration(
                  border: e.key < cats.length - 1
                      ? Border(bottom: BorderSide(color: borderColor))
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      CatIconBtn(
                        hugeIcon: HugeIcons.strokeRoundedEdit02,
                        color: AppColors.primary2,
                        onTap: () => _showCatDialog(context, ctrl, cat: cat),
                      ),
                      const SizedBox(width: 4),
                      CatIconBtn(
                        hugeIcon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.red,
                        onTap: () => _confirmDelete(context, ctrl, cat),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (cats.isNotEmpty) Divider(color: borderColor, height: 1),
            InkWell(
              onTap: () => _showCatDialog(context, ctrl),
              borderRadius: BorderRadius.vertical(
                top: cats.isEmpty ? const Radius.circular(14) : Radius.zero,
                bottom: const Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 15,
                          color: AppColors.primary2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'set_cat_add'.tr,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showCatDialog(BuildContext context, ProductsController ctrl,
      {Category? cat}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    String selectedColor = cat?.color ?? _palette[0];

    Get.dialog(StatefulBuilder(builder: (ctx, setState) {
      final bg = isDark ? AppColors.bgSurface : Colors.white;
      final borderColor =
          isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 60 : 15),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(9)),
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedGrid,
                          size: 16,
                          color: AppColors.primary2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      cat == null ? 'set_cat_new'.tr : 'set_cat_edit'.tr,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textColor),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(7)),
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: 15,
                            color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Divider(color: borderColor, height: 1)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: textColor),
                      decoration: InputDecoration(
                        labelText: 'set_cat_name'.tr,
                        labelStyle: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textGrey
                                : const Color(0xFF64748B)),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.bgCard
                            : const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary2, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('set_cat_color'.tr,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textGrey
                                : const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _palette.map((hex) {
                        final color = _hexColor(hex);
                        final sel = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: color.withAlpha(120),
                                          blurRadius: 6)
                                    ]
                                  : [],
                            ),
                            child: sel
                                ? HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle01,
                                    size: 14,
                                    color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                  color: Colors.grey.withAlpha(60)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('gen_cancel'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              if (cat == null) {
                                await ctrl.addCategory(name, selectedColor);
                              } else {
                                await ctrl.updateCategory(
                                    cat, name, selectedColor);
                              }
                              Get.back();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                                cat == null ? 'gen_add'.tr : 'gen_save'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }));
  }

  void _confirmDelete(
      BuildContext context, ProductsController ctrl, Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 60 : 15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(15),
                  shape: BoxShape.circle),
              child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: AppColors.red,
                  size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              '"${cat.name}" ${'set_cat_delete_title'.tr}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'set_cat_delete_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textGrey
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    side:
                        BorderSide(color: Colors.grey.withAlpha(60)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_cancel'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await ctrl.deleteCategory(cat.id);
                    Get.back();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gen_delete'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ));
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ── Category icon button ──────────────────────────────────────────────────────
class CatIconBtn extends StatelessWidget {
  final dynamic hugeIcon;
  final Color color;
  final VoidCallback onTap;
  const CatIconBtn(
      {super.key, this.hugeIcon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: HugeIcon(
            icon: hugeIcon ?? HugeIcons.strokeRoundedEdit02,
            size: 14,
            color: color),
      ),
    );
  }
}

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

// ── User form dialog ──────────────────────────────────────────────────────────
class UserFormDialog extends StatefulWidget {
  final User? user;
  final VoidCallback onSaved;
  const UserFormDialog({super.key, this.user, required this.onSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _form = GlobalKey<FormState>();
  final _db = Get.find<DatabaseController>().db;
  late final _name = TextEditingController(text: widget.user?.name ?? '');
  late final _pin = TextEditingController(text: widget.user?.pin ?? '');
  String _role = 'cashier';
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _role = widget.user?.role ?? 'cashier';
    _active = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: HugeIcon(
                        icon: isEdit
                            ? HugeIcons.strokeRoundedPencilEdit01
                            : HugeIcons.strokeRoundedUserAdd01,
                        size: 18,
                        color: AppColors.primary2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'set_edit_user'.tr : 'set_add_user'.tr,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _CloseBtn(),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _FormField(
                  controller: _name,
                  label: 'set_name'.tr,
                  hugeIcon: HugeIcons.strokeRoundedUser,
                  validator: (v) =>
                      v?.isEmpty == true ? 'gen_required'.tr : null,
                ),
                const SizedBox(height: 14),
                _FormField(
                  controller: _pin,
                  label: 'set_pin'.tr,
                  hugeIcon: HugeIcons.strokeRoundedLock,
                  keyboardType: TextInputType.number,
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.length < 4) return 'set_pin'.tr;
                    if (!RegExp(r'^\d+$').hasMatch(v)) {
                      return 'gen_required'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _RoleSelector(
                  selected: _role,
                  onSelect: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 14),
                _ActiveToggle(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('set_cancel'.tr,
                            style:
                                const TextStyle(fontFamily: 'Gilroy')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary2,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text(
                                isEdit
                                    ? 'set_update'.tr
                                    : 'set_save'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    if (widget.user == null) {
      await _db.createUser(UsersCompanion.insert(
        name: _name.text.trim(),
        pin: _pin.text.trim(),
        role: drift.Value(_role),
        isActive: drift.Value(_active),
      ));
    } else {
      await _db.updateUser(widget.user!.copyWith(
        name: _name.text.trim(),
        pin: _pin.text.trim(),
        role: _role,
        isActive: _active,
      ));
    }
    widget.onSaved();
    Get.back();
  }
}

class _CloseBtn extends StatelessWidget {
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
        child: const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 16,
            color: AppColors.textGrey),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final dynamic hugeIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hugeIcon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: HugeIcon(
              icon: hugeIcon, size: 18, color: AppColors.textGrey),
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? AppColors.bgBorder
                  : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark
                  ? AppColors.bgBorder
                  : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppColors.primary2, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _RoleSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('set_role'.tr,
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                color: AppColors.textGrey)),
        const SizedBox(height: 8),
        Row(
          children: [
            _RoleChip(
              value: 'cashier',
              label: 'set_role_cashier'.tr,
              hugeIcon: HugeIcons.strokeRoundedCashier,
              color: AppColors.blue,
              selected: selected == 'cashier',
              onTap: () => onSelect('cashier'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _RoleChip(
              value: 'admin',
              label: 'set_role_admin'.tr,
              hugeIcon: HugeIcons.strokeRoundedShield02,
              color: AppColors.primary2,
              selected: selected == 'admin',
              onTap: () => onSelect('admin'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String value;
  final String label;
  final dynamic hugeIcon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _RoleChip({
    required this.value,
    required this.label,
    required this.hugeIcon,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  Color get _solidColor {
    if (color == AppColors.blue) return const Color(0xFF3B82F6);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _solidColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor
              : (isDark ? AppColors.bgCard : const Color(0xFFF8FAFF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? activeColor
                : (isDark
                    ? AppColors.bgBorder
                    : const Color(0xFFE2E8F0)),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: activeColor.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: hugeIcon,
              size: 15,
              color: selected ? Colors.white : AppColors.textGrey,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textGrey,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  size: 14,
                  color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _ActiveToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.green : AppColors.red;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'set_active'.tr,
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.green,
              inactiveThumbColor: AppColors.red,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
