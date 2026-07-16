import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/database/app_database.dart';
import '../../../controllers/database_controller.dart';
import '../../../core/constants/color_constants.dart';

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
