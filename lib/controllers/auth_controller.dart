import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/permissions.dart';
import '../data/database/app_database.dart';
import '../features/auth/widgets/admin_override_dialog.dart';
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
      AdminOverrideDialog(reason: reason, db: _db),
      barrierDismissible: false,
    );
    return success == true;
  }
}
