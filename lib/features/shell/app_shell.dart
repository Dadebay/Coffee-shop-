import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/ingredients_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/color_constants.dart';
import '../pos/pos_screen.dart';
import '../products/products_screen.dart';
import '../ingredients/ingredients_screen.dart';
import '../recipes/recipes_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_movements_screen.dart';
import '../stock/stock_report_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _idx;
  late final bool _isAdmin;

  // Nav item definitions — order is rebalanced per role in getters below
  static const _allPages = [
    PosScreen(),
    ProductsScreen(),
    IngredientsScreen(),
    RecipesScreen(),
    ReportsScreen(),
    SettingsScreen(),
    StockMovementsScreen(),
    StockReportScreen(),
  ];

  static final _allIcons = [
    HugeIcons.strokeRoundedCashier,
    HugeIcons.strokeRoundedPackage,
    HugeIcons.strokeRoundedWarehouse,
    HugeIcons.strokeRoundedBook02,
    HugeIcons.strokeRoundedChartBarLine,
    HugeIcons.strokeRoundedSettings01,
    HugeIcons.strokeRoundedDeliveryReturn01,
    HugeIcons.strokeRoundedAnalytics01,
  ];

  static const _allKeys = [
    'nav_pos',
    'nav_products',
    'nav_stock',
    'nav_recipes',
    'nav_reports',
    'nav_settings',
    'nav_stock_movements',
    'nav_stock_report',
  ];

  // Admin order: Reports, POS, Products, Ingredients, Recipes, StockMovements, StockReport, Settings
  static const _adminOrder    = [4, 0, 1, 6, 7, 2, 3, 5];
  // Cashier order: POS first (Settings last)
  static const _cashierOrder  = [0, 1, 2, 6, 7, 3, 4, 5];

  List<int> get _order => _isAdmin ? _adminOrder : _cashierOrder;

  List<Widget>           get _pages    => _order.map((i) => _allPages[i]).toList();
  List<List<List<dynamic>>> get _navIcons => _order.map((i) => _allIcons[i]).toList();
  List<String>           get _navKeys  => _order.map((i) => _allKeys[i]).toList();

  @override
  void initState() {
    super.initState();
    _isAdmin = AuthController.to.isAdmin;
    // Always start at index 0 — first item is already role-correct
    _idx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildRail(context),
          Expanded(child: _pages[_idx]),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    final auth = AuthController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xffEEEEF2);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xffE0E0E6);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCoffee01,
              color: AppColors.primary2,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, indent: 12, endIndent: 12, height: 1),
          const SizedBox(height: 8),

          // Nav items
          ...List.generate(_navIcons.length, (i) {
            final selected = _idx == i;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
              child: Tooltip(
                message: _navKeys[i].tr,
                preferBelow: false,
                child: GestureDetector(
                  onTap: () => setState(() => _idx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withAlpha(30) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: AppColors.primary.withAlpha(60))
                          : null,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: _navIcons[i],
                        size: 22,
                        color: selected ? AppColors.primary2 : AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // Low stock badge
          Obx(() {
            final count = Get.find<IngredientsController>().lowStock.length;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tooltip(
                message: '$count ${'gen_low_stock_warning'.tr}',
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.red.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.red.withAlpha(80)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),

          Divider(color: borderColor, indent: 12, endIndent: 12, height: 1),

          // Bottom controls: theme + language + user + logout
          Obx(() {
            final user = auth.currentUser.value;
            final initial = user?.name.substring(0, 1).toUpperCase() ?? '?';
            final themeCtrl = ThemeController.to;
            final localeCtrl = LocaleController.to;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Column(
                children: [
                  // Theme toggle
                  Tooltip(
                    message: themeCtrl.isDark.value
                        ? 'set_light_mode'.tr
                        : 'set_dark_mode'.tr,
                    child: GestureDetector(
                      onTap: themeCtrl.toggle,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: themeCtrl.isDark.value
                                ? HugeIcons.strokeRoundedSun03
                                : HugeIcons.strokeRoundedMoon02,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Language switcher
                  _LangSwitcher(localeCtrl: localeCtrl),
                  const SizedBox(height: 8),

                  // User avatar
                  Tooltip(
                    message: user?.name ?? '',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withAlpha(40),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.primary2,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Logout
                  Tooltip(
                    message: 'gen_logout'.tr,
                    child: GestureDetector(
                      onTap: auth.logout,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLogout01,
                          size: 18,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Language switcher cycling between RU → TK ─────────────────────────────────
class _LangSwitcher extends StatelessWidget {
  final LocaleController localeCtrl;
  const _LangSwitcher({required this.localeCtrl});

  static const _locales = [Locale('ru'), Locale('tk')];
  static const _flags   = ['assets/icons/ruflag.svg', 'assets/icons/tmflag.svg'];
  static const _labels  = ['RU', 'TM'];

  @override
  Widget build(BuildContext context) {
    final code = localeCtrl.currentCode;
    // If somehow 'tr' is still active, treat it as 'ru'
    final idx     = _locales.indexWhere((l) => l.languageCode == code).clamp(0, 1);
    final nextIdx = (idx + 1) % _locales.length;

    return Tooltip(
      message: '${'set_language'.tr}: ${_labels[nextIdx]}',
      child: GestureDetector(
        onTap: () => localeCtrl.setLocale(_locales[nextIdx]),
        child: Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.bgBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: SvgPicture.asset(_flags[idx], fit: BoxFit.cover, width: 36, height: 28),
        ),
      ),
    );
  }
}
