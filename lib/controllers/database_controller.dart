import 'package:get/get.dart';
import '../data/database/app_database.dart';

class DatabaseController extends GetxController {
  late final AppDatabase db;

  @override
  void onInit() {
    super.onInit();
    db = AppDatabase();
  }

  @override
  void onClose() {
    db.close();
    super.onClose();
  }
}
