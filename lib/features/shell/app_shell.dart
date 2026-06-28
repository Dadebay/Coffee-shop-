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

const double _kCollapsedWidth = 72.0;
const double _kExpandedWidth  = 220.0;
const double _kDesktopBreak   = 1000.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _idx;
  late final bool _isAdmin;
  bool _expanded = true; // manually toggled by user

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

  static const _adminOrder   = [4, 0, 1, 6, 7, 2, 3, 5];
  static const _cashierOrder = [0, 1, 2, 6, 7, 3, 4, 5];

  List<int>               get _order    => _isAdmin ? _adminOrder : _cashierOrder;
  List<Widget>            get _pages    => _order.map((i) => _allPages[i]).toList();
  List<List<List<dynamic>>> get _navIcons => _order.map((i) => _allIcons[i]).toList();
  List<String>            get _navKeys  => _order.map((i) => _allKeys[i]).toList();

  @override
  void initState() {
    super.initState();
    _isAdmin = AuthController.to.isAdmin;
    _idx = 0;
  }

  bool _isDesktop(double width) => width >= _kDesktopBreak;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(width);

    // On tablet: always collapsed unless user explicitly expanded
    // On desktop: default expanded, user can collapse
    final bool showExpanded = isDesktop ? _expanded : false;

    return Scaffold(
      body: Row(
        children: [
          _AnimatedRail(
            expanded: showExpanded,
            isDesktop: isDesktop,
            onToggle: isDesktop ? () => setState(() => _expanded = !_expanded) : null,
            idx: _idx,
            navIcons: _navIcons,
            navKeys: _navKeys,
            onSelect: (i) => setState(() => _idx = i),
            onLowStockTap: () {
              final target = _order.indexOf(6); // 6 is StockMovementsScreen
              if (target != -1) {
                setState(() => _idx = target);
              }
            },
          ),
          Expanded(child: _pages[_idx]),
        ],
      ),
    );
  }
}

// ── Animated sidebar rail ──────────────────────────────────────────────────────
class _AnimatedRail extends StatelessWidget {
  final bool expanded;
  final bool isDesktop;
  final VoidCallback? onToggle;
  final int idx;
  final List<List<List<dynamic>>> navIcons;
  final List<String> navKeys;
  final ValueChanged<int> onSelect;
  final VoidCallback onLowStockTap;

  const _AnimatedRail({
    required this.expanded,
    required this.isDesktop,
    required this.onToggle,
    required this.idx,
    required this.navIcons,
    required this.navKeys,
    required this.onSelect,
    required this.onLowStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth    = AuthController.to;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.bgSurface : Colors.white;
    final border  = isDark ? AppColors.bgBorder  : const Color(0xffE8E8EE);
    final targetW = expanded ? _kExpandedWidth : _kCollapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: targetW,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // ── Header: logo + toggle button ─────────────────────────
          SizedBox(
            height: 44,
            child: ClipRect(
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: expanded ? null : 0,
                      child: expanded
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    'Owaz Coffee',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const Spacer(),
                  if (onToggle != null)
                    _ToggleBtn(expanded: expanded, onTap: onToggle!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: border, indent: 12, endIndent: 12, height: 1),
          const SizedBox(height: 8),

          // ── Nav items ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navIcons.length,
              itemBuilder: (_, i) {
                final selected = idx == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  child: Tooltip(
                    message: expanded ? '' : navKeys[i].tr,
                    preferBelow: false,
                    child: GestureDetector(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary2.withAlpha(isDark ? 25 : 15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: AppColors.primary2.withAlpha(isDark ? 80 : 60), width: 1.2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: _kCollapsedWidth - 16,
                              child: Center(
                                child: HugeIcon(
                                  icon: navIcons[i],
                                  size: 20,
                                  color: selected
                                      ? AppColors.primary2
                                      : AppColors.textGrey,
                                ),
                              ),
                            ),
                            if (expanded)
                              Expanded(
                                child: AnimatedOpacity(
                                  opacity: expanded ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Text(
                                    navKeys[i].tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.primary2
                                          : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Low stock badge ────────────────────────────────────────
          _LowStockBadge(expanded: expanded, onTap: onLowStockTap),

          Divider(color: border, indent: 12, endIndent: 12, height: 1),

          // ── Bottom: user + logout ──────────────────────────────────
          Obx(() {
            final user    = auth.currentUser.value;
            final initial = user?.name.substring(0, 1).toUpperCase() ?? '?';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: expanded
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withAlpha(40),
                          child: Text(initial,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              color: AppColors.primary2,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                user?.role ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 10,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'gen_logout'.tr,
                          child: GestureDetector(
                            onTap: auth.logout,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLogout01,
                              size: 18,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: user?.name ?? '',
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withAlpha(40),
                            child: Text(initial,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                color: AppColors.primary2,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 52,
                            child: Text(
                              user.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textWhite.withAlpha(180) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Tooltip(
                          message: 'gen_logout'.tr,
                          child: GestureDetector(
                            onTap: auth.logout,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLogout01,
                              size: 18,
                              color: AppColors.textGrey,
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

// ── Expand/collapse toggle button ──────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _ToggleBtn({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard : const Color(0xFFE8E8EE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedRotation(
          turns: expanded ? 0.0 : 0.5,
          duration: const Duration(milliseconds: 220),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 14,
            color: AppColors.textGrey,
          ),
        ),
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
    final code    = localeCtrl.currentCode;
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

// ── Low stock badge — safe wrapper around IngredientsController ───────────────
class _LowStockBadge extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _LowStockBadge({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<IngredientsController>()) {
      return const SizedBox.shrink();
    }
    final ctrl = Get.find<IngredientsController>();
    return Obx(() {
      final count = ctrl.lowStock.length;
      if (count == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: '$count ${'gen_low_stock_warning'.tr}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: expanded
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.red.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.red.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('$count',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'gen_low_stock_warning'.tr,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.red,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.red.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.red.withAlpha(80)),
                  ),
                  alignment: Alignment.center,
                  child: Text('$count',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
                ),
            ),
          ),
        ),
      );
    });
  }
}
