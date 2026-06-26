import 'package:get/get.dart';
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
    if (pin.value.length >= 4) _tryLogin();
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
    final user = await _db.getUserByPin(pin.value);
    loading.value = false;

    if (user != null) {
      currentUser.value = user;
      Get.offAllNamed('/home');
    } else if (pin.value.length >= 6) {
      error.value = 'Yanlış PIN';
      pin.value = '';
    }
  }

  void logout() {
    currentUser.value = null;
    pin.value = '';
    error.value = '';
    Get.offAllNamed('/login');
  }
}
