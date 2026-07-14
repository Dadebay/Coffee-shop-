import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/database/app_database.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/color_constants.dart';
import '../../controllers/print_controller.dart';
import '../../controllers/settings_controller.dart';
import 'action_log_screen.dart';
import 'widgets/set_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = Get.find<DatabaseController>().db;
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _db.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgSurface : const Color(0xFFF4F4F8);
    final isAdmin = AuthController.to.isAdmin;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'set_title'.tr,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Col 1 — Appearance + Language + Printer + Action log
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              icon: HugeIcons.strokeRoundedPaintBoard,
                              label: 'set_theme'.tr,
                            ),
                            const SizedBox(height: 10),
                            _AppearanceCard(),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              icon: HugeIcons.strokeRoundedLanguageCircle,
                              label: 'set_language'.tr,
                            ),
                            const SizedBox(height: 10),
                            _LanguageCard(),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              icon: HugeIcons.strokeRoundedPrinter,
                              label: 'set_printer'.tr,
                            ),
                            const SizedBox(height: 10),
                            const _PrinterCard(),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              icon: HugeIcons.strokeRoundedReturnRequest,
                              label: 'pos_returns'.tr,
                            ),
                            const SizedBox(height: 10),
                            const _ReturnsCard(),
                            if (isAdmin) ...[
                              const SizedBox(height: 24),
                              _SectionHeader(
                                icon: HugeIcons.strokeRoundedTask01,
                                label: 'log_title'.tr,
                              ),
                              const SizedBox(height: 10),
                              _ActionLogNavCard(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Col 2 — Categories
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              icon: HugeIcons.strokeRoundedGrid,
                              label: 'set_categories'.tr,
                            ),
                            const SizedBox(height: 10),
                            const CategoryCard(),
                          ],
                        ),
                      ),

                      // Col 3 — Users (admin only)
                      if (isAdmin) ...[
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  _SectionHeader(
                                    icon:
                                        HugeIcons.strokeRoundedUserGroup,
                                    label: 'set_users'.tr,
                                  ),
                                  const Spacer(),
                                  _AddUserBtn(onTap: () => _showForm()),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ..._users.map((u) => UserTile(
                                    key: ValueKey(u.id),
                                    user: u,
                                    onEdit: () => _showForm(user: u),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _showForm({User? user}) {
    Get.dialog(UserFormDialog(user: user, onSaved: _load));
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: 15,
          color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
        ),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ── Appearance card ───────────────────────────────────────────────────────────
class _AppearanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor =
        isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final dark = themeCtrl.isDark.value;
        return InkWell(
          onTap: () => themeCtrl.setDark(!dark),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: dark
                          ? HugeIcons.strokeRoundedMoon02
                          : HugeIcons.strokeRoundedSun03,
                      size: 20,
                      color: AppColors.primary2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dark ? 'set_dark_mode'.tr : 'set_light_mode'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dark ? 'set_light_mode'.tr : 'set_dark_mode'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: dark,
                  onChanged: themeCtrl.setDark,
                  activeThumbColor: AppColors.primary2,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Language card ─────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  static const _locales = [
    (code: 'ru', label: 'Русский', flag: 'assets/icons/ruflag.svg'),
    (code: 'tk', label: 'Türkmençe', flag: 'assets/icons/tmflag.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final localeCtrl = LocaleController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor =
        isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Obx(() {
        final current = localeCtrl.currentCode;
        return Column(
          children: _locales.map((lang) {
            final selected = current == lang.code;
            return GestureDetector(
              onTap: () => localeCtrl.setLocale(Locale(lang.code)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary2
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SvgPicture.asset(
                        lang.flag,
                        width: 28,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.label,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? AppColors.primary2 : null,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary2,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                            icon: HugeIcons
                                .strokeRoundedCheckmarkCircle01,
                            size: 13,
                            color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}

// ── Printer card ──────────────────────────────────────────────────────────────
class _PrinterCard extends StatelessWidget {
  const _PrinterCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final print = PrintController.to;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final printers = print.printers;
        final selected = print.selectedPrinter.value;
        final auto = print.autoPrint.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary2.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPrinter,
                          size: 18,
                          color: AppColors.primary2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: printers.isEmpty
                      ? Text('set_printer_none'.tr,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              color: AppColors.textGrey))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: printers.contains(selected)
                                ? selected
                                : null,
                            hint: Text('set_printer_select'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy', fontSize: 13)),
                            isExpanded: true,
                            style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                            dropdownColor:
                                isDark ? AppColors.bgCard : Colors.white,
                            items: printers
                                .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 13))))
                                .toList(),
                            onChanged: (v) =>
                                print.selectPrinter(v ?? ''),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: print.refreshPrinters,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bgSurface
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: border),
                    ),
                    child: const Center(
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedRefresh,
                            size: 16,
                            color: AppColors.textGrey)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => print.setAutoPrint(!auto),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('set_printer_auto'.tr,
                            style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('set_printer_auto_desc'.tr,
                            style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  Switch(
                      value: auto,
                      onChanged: print.setAutoPrint,
                      activeThumbColor: AppColors.primary2),
                ],
              ),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await print.testPrint();
                    Get.snackbar(
                      ok ? 'gen_success'.tr : 'gen_error'.tr,
                      ok
                          ? 'set_printer_test_ok'.tr
                          : 'set_printer_test_fail'.tr,
                      backgroundColor:
                          (ok ? AppColors.green : AppColors.red)
                              .withAlpha(200),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                        color: AppColors.primary2.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPrinter,
                      size: 16,
                      color: AppColors.primary2),
                  label: Text('set_printer_test'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary2)),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

// ── Returns card ──────────────────────────────────────────────────────────────
class _ReturnsCard extends StatelessWidget {
  const _ReturnsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final settings = SettingsController.to;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final restore = settings.restoreStockOnReturn.value;
        return GestureDetector(
          onTap: () => settings.setRestoreStockOnReturn(!restore),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('set_restore_stock'.tr,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('set_restore_stock_desc'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            color: AppColors.textGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                  value: restore,
                  onChanged: settings.setRestoreStockOnReturn,
                  activeThumbColor: AppColors.primary2),
            ],
          ),
        );
      }),
    );
  }
}

// ── Action log nav card ───────────────────────────────────────────────────────
class _ActionLogNavCard extends StatelessWidget {
  const _ActionLogNavCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: () => Get.to(() => const ActionLogScreen()),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 0 : 5),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.purple.withAlpha(isDark ? 50 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: HugeIcon(
                    icon: HugeIcons.strokeRoundedTask01,
                    color: AppColors.purple,
                    size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('log_title'.tr,
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textWhite
                              : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('log_subtitle'.tr,
                      style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          color: AppColors.textGrey)),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: isDark
                  ? AppColors.textGrey
                  : const Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add user button ───────────────────────────────────────────────────────────
class _AddUserBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddUserBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedUserAdd01,
          size: 16,
          color: Colors.white),
      label: Text(
        'set_add_user'.tr,
        style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            fontSize: 13),
      ),
    );
  }
}
