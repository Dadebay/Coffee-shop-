import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/action_log_controller.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_date_range_picker.dart';
import '../../data/database/app_database.dart';

class ActionLogScreen extends StatelessWidget {
  const ActionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ActionLogController());
    final ctrl = ActionLogController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFF5F5F7);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: textColor, size: 22),
        ),
        title: Text(
          'log_title'.tr,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          Obx(() {
            final hasFilter = ctrl.selectedUserId.value != null ||
                ctrl.selectedActionType.value != null;
            if (!hasFilter) return const SizedBox.shrink();
            return TextButton(
              onPressed: ctrl.clearFilters,
              child: Text('log_clear'.tr,
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.red,
                      fontWeight: FontWeight.w600)),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(ctrl, isDark),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary2));
              }
              if (ctrl.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTask01,
                        color: AppColors.textGrey,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'log_empty'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.textGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: ctrl.logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = ctrl.logs[i];
                  final log = entry['log'] as ActionLog;
                  final userName = entry['userName'] as String;
                  return _LogCard(log: log, userName: userName, isDark: isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ActionLogController ctrl, bool isDark) {
    final cardBg = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Obx(() => Row(
        children: [
          // Date range pill
          GestureDetector(
            onTap: () => _pickRange(ctrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary2.withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary2.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: AppColors.primary2, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${formatDate(ctrl.fromDate.value)} – ${formatDate(ctrl.toDate.value)}',
                    style: const TextStyle(
                        fontFamily: 'Gilroy',
                        color: AppColors.primary2,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // User filter
          _FilterDropdown<int?>(
            value: ctrl.selectedUserId.value,
            hint: 'log_all_users'.tr,
            items: [
              DropdownMenuItem(value: null, child: Text('log_all_users'.tr, style: _dropdownStyle(isDark))),
              ...ctrl.users.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name, style: _dropdownStyle(isDark)))),
            ],
            onChanged: ctrl.setUser,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          // Action type filter
          _FilterDropdown<String?>(
            value: ctrl.selectedActionType.value,
            hint: 'log_all_types'.tr,
            items: [
              DropdownMenuItem(value: null, child: Text('log_all_types'.tr, style: _dropdownStyle(isDark))),
              ...ActionLogController.actionTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        _actionBadgeSmall(t),
                        const SizedBox(width: 8),
                        Text(_localizeType(t), style: _dropdownStyle(isDark)),
                      ],
                    ),
                  )),
            ],
            onChanged: ctrl.setActionType,
            isDark: isDark,
          ),
          const Spacer(),
          Obx(() => Text(
                '${ctrl.logs.length} ${'log_records'.tr}',
                style: const TextStyle(
                    fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500),
              )),
        ],
      )),
    );
  }

  TextStyle _dropdownStyle(bool isDark) => TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
      );

  Future<void> _pickRange(ActionLogController ctrl) async {
    final context = Get.context!;
    final range = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: ctrl.fromDate.value, end: ctrl.toDate.value),
    );
    if (range != null) ctrl.setDateRange(range.start, range.end);
  }
}

// ─────────────────────────────── Log Card ──────────────────────────────────
class _LogCard extends StatelessWidget {
  final ActionLog log;
  final String userName;
  final bool isDark;

  const _LogCard({required this.log, required this.userName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final dimColor = isDark ? AppColors.textGrey : const Color(0xFF64748B);
    final typeColor = _typeColor(log.action);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent line
          Container(
            width: 3,
            height: 46,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withAlpha(isDark ? 40 : 20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(icon: _typeIcon(log.action), color: typeColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActionBadge(type: log.action),
                    const Spacer(),
                    Text(
                      formatDateTime(log.createdAt),
                      style: TextStyle(
                          fontFamily: 'Gilroy', fontSize: 12, color: dimColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.description,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedUser, color: dimColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      userName,
                      style: TextStyle(
                          fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: dimColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Action Badge ──────────────────────────────────
class _ActionBadge extends StatelessWidget {
  final String type;
  const _ActionBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 50 : 25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        _localizeType(type),
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

Widget _actionBadgeSmall(String type) {
  final color = _typeColor(type);
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─────────────────────── Filter Dropdown ──────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.bgCard : const Color(0xFFF8FAFC);
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  fontFamily: 'Gilroy', fontSize: 13, color: AppColors.textGrey)),
          items: items,
          onChanged: (v) => onChanged(v as T),
          dropdownColor: isDark ? AppColors.bgCard : Colors.white,
          style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: textColor),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: AppColors.textGrey, size: 14),
        ),
      ),
    );
  }
}

// ──────────────────────── Helpers ─────────────────────────────────────────
Color _typeColor(String type) {
  switch (type) {
    case 'sale':      return AppColors.green;
    case 'cancel':
    case 'return':    return AppColors.red;
    case 'price_change': return AppColors.orange;
    case 'stock_adjust': return AppColors.primary2;
    case 'shift_close': return AppColors.purple;
    case 'shift_open': return const Color(0xFF06B6D4);
    default:          return AppColors.textGrey;
  }
}

List<List<dynamic>> _typeIcon(String type) {
  switch (type) {
    case 'sale':       return HugeIcons.strokeRoundedShoppingCart01;
    case 'cancel':
    case 'return':     return HugeIcons.strokeRoundedCancel01;
    case 'price_change': return HugeIcons.strokeRoundedMoney02;
    case 'stock_adjust': return HugeIcons.strokeRoundedPackage;
    case 'shift_close':  return HugeIcons.strokeRoundedDoor01;
    case 'shift_open':   return HugeIcons.strokeRoundedDoor01;
    default:             return HugeIcons.strokeRoundedTask01;
  }
}

String _localizeType(String type) {
  switch (type) {
    case 'sale':          return 'log_type_sale'.tr;
    case 'cancel':        return 'log_type_cancel'.tr;
    case 'return':        return 'log_type_return'.tr;
    case 'price_change':  return 'log_type_price'.tr;
    case 'stock_adjust':  return 'log_type_stock'.tr;
    case 'shift_close':   return 'log_type_shift_close'.tr;
    case 'shift_open':    return 'log_type_shift_open'.tr;
    default:              return type;
  }
}

String formatDateTime(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
