// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/constants/color_constants.dart';
import '../core/permissions.dart';
import '../data/database/app_database.dart';
import 'database_controller.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString pin = ''.obs;
  final RxString error = ''.obs;
  final RxBool loading = false.obs;

  bool get isAdmin => currentUser.value?.role == 'admin';

  void addDigit(String digit) {
    if (pin.value.length >= 6) return;
    pin.value += digit;
    error.value = '';
    if (pin.value.length >= 6) _tryLogin();
  }

  Future<void> tryLogin() async {
    if (pin.value.length < 4) {
      error.value = 'En az 4 rakam girin';
      return;
    }
    await _tryLogin();
  }

  void backspace() {
    if (pin.value.isNotEmpty) {
      pin.value = pin.value.substring(0, pin.value.length - 1);
    }
  }

  void clearPin() {
    pin.value = '';
    error.value = '';
  }

  Future<void> _tryLogin() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final user = await _db.getUserByPin(pin.value);
      if (user != null) {
        currentUser.value = user;
        // Close any open dialogs (Get.dialog uses rootNavigator, offAllNamed won't clear them)
        try {
          final nav = Navigator.of(Get.context!, rootNavigator: true);
          nav.popUntil((r) => r.isFirst);
        } catch (_) {}
        Get.offAllNamed('/home');
      } else {
        error.value = 'Yanlış PIN';
        pin.value = '';
      }
    } catch (e) {
      error.value = 'Bağlantı hatası';
      pin.value = '';
    } finally {
      loading.value = false;
    }
  }

  void logout() {
    currentUser.value = null;
    pin.value = '';
    error.value = '';
    try {
      final nav = Navigator.of(Get.context!, rootNavigator: true);
      nav.popUntil((r) => r.isFirst);
    } catch (_) {}
    Get.offAllNamed('/login');
  }

  // ── Permissions (Feature 6) ───────────────────────────────────────────────

  bool can(Permission p) {
    final role = currentUser.value?.role;
    if (role == null) return false;
    return role.hasPermission(p);
  }

  Future<bool> requireAdmin(String reason) async {
    // Already an admin
    if (isAdmin) return true;

    // Otherwise ask for an admin PIN
    final success = await Get.dialog<bool>(
      _AdminOverrideDialog(reason: reason, db: _db),
      barrierDismissible: false,
    );
    return success == true;
  }
}

// ── Admin Override Dialog ───────────────────────────────────────────────────

class _AdminOverrideDialog extends StatefulWidget {
  final String reason;
  final AppDatabase db;
  const _AdminOverrideDialog({required this.reason, required this.db});

  @override
  State<_AdminOverrideDialog> createState() => _AdminOverrideDialogState();
}

class _AdminOverrideDialogState extends State<_AdminOverrideDialog> {
  String _pin = '';
  String _error = '';
  bool _loading = false;

  void _addDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = '';
    });
    if (_pin.length >= 4) _tryApprove();
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _error = '';
    });
  }

  Future<void> _tryApprove() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final user = await widget.db.getUserByPin(_pin);
      if (user != null && user.role == 'admin') {
        Get.back(result: true);
      } else {
        setState(() => _error = 'auth_invalid_pin'.tr);
        _pin = '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const HugeIcon(
                icon: HugeIcons.strokeRoundedShield02,
                size: 48,
                color: AppColors.red),
            const SizedBox(height: 16),
            Text('auth_admin_approval'.tr,
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textWhite
                        : const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('auth_admin_req_desc'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    color: AppColors.textGrey)),
            const SizedBox(height: 8),
            Text(widget.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red)),
            const SizedBox(height: 24),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  6, (i) => _PinDot(filled: i < _pin.length, isDark: isDark)),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _error.isEmpty
                  ? const SizedBox(height: 16)
                  : Text(_error,
                      key: const ValueKey('err'),
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // Numpad
            _SmallNumpad(
                onDigit: _addDigit,
                onBackspace: _backspace,
                onClear: _clearPin,
                isDark: isDark),
            const SizedBox(height: 20),

            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('auth_cancel'.tr,
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  final bool isDark;
  const _PinDot({required this.filled, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary2 : Colors.transparent,
        border: Border.all(
          color: filled
              ? AppColors.primary2
              : (isDark ? AppColors.bgBorder : const Color(0xFFCBD5E1)),
          width: 2,
        ),
      ),
    );
  }
}

class _SmallNumpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool isDark;

  const _SmallNumpad(
      {required this.onDigit,
      required this.onBackspace,
      required this.onClear,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫']
    ];
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: r
                      .map((k) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _NumKeySmall(
                              label: k,
                              isAction: k == 'C' || k == '⌫',
                              isDark: isDark,
                              onTap: () {
                                if (k == '⌫')
                                  onBackspace();
                                else if (k == 'C')
                                  onClear();
                                else
                                  onDigit(k);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }
}

class _NumKeySmall extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final bool isDark;

  const _NumKeySmall(
      {required this.label,
      required this.onTap,
      this.isAction = false,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isAction
        ? Colors.transparent
        : (isDark ? AppColors.bgCard : const Color(0xFFF1F5F9));
    final border = isAction
        ? Colors.transparent
        : (isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0));
    final textCol = isAction
        ? AppColors.textGrey
        : (isDark ? AppColors.textWhite : const Color(0xFF0F172A));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 60,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textCol),
          ),
        ),
      ),
    );
  }
}
