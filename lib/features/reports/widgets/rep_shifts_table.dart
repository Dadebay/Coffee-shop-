import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

// ── Shifts table ───────────────────────────────────────────────────────────────

class RepShiftsTable extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  final int? selectedShiftId;
  final Color borderColor;
  final bool isDark;
  final void Function(Shift?, String) onSelect;

  const RepShiftsTable({
    super.key,
    required this.shifts,
    required this.selectedShiftId,
    required this.borderColor,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurface : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const SizedBox(
                width: 36,
                child: Text('#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textGrey))),
            Expanded(flex: 2, child: _th('emp_name'.tr)),
            Expanded(flex: 2, child: _th('shift_opened_at'.tr)),
            Expanded(flex: 2, child: _th('shift_close'.tr)),
            Expanded(child: _th('shift_hours'.tr, center: true)),
            Expanded(child: _th('rep_orders'.tr, center: true)),
            Expanded(flex: 2, child: _th('rep_revenue'.tr, right: true)),
            Expanded(child: _th('shift_status'.tr, center: true)),
          ]),
        ),
        Divider(color: borderColor, height: 1),
        // Rows
        ...shifts.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final shift = row['shift'] as Shift;
          final userName = row['userName'] as String;
          final isOpen = shift.closedAt == null;
          final isLast = i == shifts.length - 1;
          final isSelected = selectedShiftId == shift.id;
          final duration =
              (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
          final h = duration.inHours;
          final m = duration.inMinutes.remainder(60);

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSelect(
                  isSelected ? null : shift, isSelected ? '' : userName),
              child: Column(children: [
                Container(
                  color: isSelected
                      ? AppColors.primary2.withAlpha(isDark ? 25 : 12)
                      : isOpen
                          ? AppColors.green.withAlpha(isDark ? 15 : 8)
                          : Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    SizedBox(
                      width: 36,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary2
                                  : AppColors.textGrey)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary2.withAlpha(isDark ? 40 : 20),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primary2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(userName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : const Color(0xFF0F172A))),
                        ),
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmt(shift.openedAt),
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text('${shift.openingCash.toStringAsFixed(0)} TMT',
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: isOpen
                          ? const Text('—',
                              style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.textGrey))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fmt(shift.closedAt!),
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(
                                    '${(shift.closingCash ?? 0).toStringAsFixed(0)} TMT',
                                    style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 11,
                                        color: AppColors.textGrey)),
                              ],
                            ),
                    ),
                    Expanded(
                      child: Text('${h}s ${m}d',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  h >= 8 ? AppColors.red : AppColors.textGrey)),
                    ),
                    Expanded(
                      child: Text('${shift.orderCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary2)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(formatCurrency(shift.totalRevenue),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green)),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.green.withAlpha(isDark ? 40 : 20)
                                : AppColors.textGrey
                                    .withAlpha(isDark ? 40 : 15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOpen
                                  ? AppColors.green.withAlpha(80)
                                  : AppColors.bgBorder,
                            ),
                          ),
                          child: Text(
                            isOpen ? 'shift_open'.tr : 'shift_closed'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  isOpen ? AppColors.green : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                if (!isLast) Divider(color: borderColor, height: 1),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _th(String t, {bool center = false, bool right = false}) => Text(t,
      textAlign: center
          ? TextAlign.center
          : right
              ? TextAlign.right
              : TextAlign.left,
      style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textGrey));

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }
}
