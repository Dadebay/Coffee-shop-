import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/database/app_database.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/color_constants.dart';
import 'widgets/set_widgets.dart';
import 'widgets/settings_cards.dart';

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
                            SectionHeader(
                              icon: HugeIcons.strokeRoundedPaintBoard,
                              label: 'set_theme'.tr,
                            ),
                            const SizedBox(height: 10),
                            AppearanceCard(),
                            const SizedBox(height: 24),
                            SectionHeader(
                              icon: HugeIcons.strokeRoundedLanguageCircle,
                              label: 'set_language'.tr,
                            ),
                            const SizedBox(height: 10),
                            LanguageCard(),
                            const SizedBox(height: 24),
                            SectionHeader(
                              icon: HugeIcons.strokeRoundedPrinter,
                              label: 'set_printer'.tr,
                            ),
                            const SizedBox(height: 10),
                            const PrinterCard(),
                            const SizedBox(height: 24),
                            SectionHeader(
                              icon: HugeIcons.strokeRoundedReturnRequest,
                              label: 'pos_returns'.tr,
                            ),
                            const SizedBox(height: 10),
                            const ReturnsCard(),
                            if (isAdmin) ...[
                              const SizedBox(height: 24),
                              SectionHeader(
                                icon: HugeIcons.strokeRoundedTask01,
                                label: 'log_title'.tr,
                              ),
                              const SizedBox(height: 10),
                              ActionLogNavCard(),
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
                            SectionHeader(
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
                                  SectionHeader(
                                    icon:
                                        HugeIcons.strokeRoundedUserGroup,
                                    label: 'set_users'.tr,
                                  ),
                                  const Spacer(),
                                  AddUserBtn(onTap: () => _showForm()),
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

