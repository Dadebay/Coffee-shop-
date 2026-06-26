import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'controllers/database_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/pos_controller.dart';
import 'controllers/products_controller.dart';
import 'controllers/ingredients_controller.dart';
import 'controllers/recipes_controller.dart';
import 'controllers/reports_controller.dart';
import 'controllers/shift_controller.dart';
import 'controllers/stock_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/locale_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KassaApp());
}

class KassaApp extends StatelessWidget {
  const KassaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.put(ThemeController(), permanent: true);
    return Obx(() => GetMaterialApp(
          title: 'Kassa – Coffee Shop POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeCtrl.themeMode,
          translations: AppTranslations(),
          locale: const Locale('ru'),
          fallbackLocale: const Locale('ru'),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          initialBinding: AppBindings(),
          initialRoute: '/login',
          getPages: [
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/home',  page: () => const AppShell()),
          ],
        ));
  }
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(LocaleController(), permanent: true);
    Get.put(DatabaseController(), permanent: true);
    Get.put(AuthController(),     permanent: true);
    Get.put(CartController(),     permanent: true);
    Get.put(ShiftController(),    permanent: true);
    Get.lazyPut(() => PosController());
    Get.lazyPut(() => ProductsController());
    Get.lazyPut(() => IngredientsController());
    Get.lazyPut(() => RecipesController());
    Get.lazyPut(() => ReportsController());
    Get.lazyPut(() => StockController());
  }
}
