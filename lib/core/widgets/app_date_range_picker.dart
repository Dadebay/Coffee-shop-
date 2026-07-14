import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';

/// A fully-translated (tr/ru/tk) date-range calendar with explicit
/// prev/next month arrows, replacing Flutter's built-in
/// [showDateRangePicker] (English-only, scroll-to-navigate).
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTimeRange initialDateRange,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Get.dialog<DateTimeRange>(
    _RangePickerDialog(
      firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day),
      lastDate: DateTime(lastDate.year, lastDate.month, lastDate.day),
      initialStart: initialDateRange.start,
      initialEnd: initialDateRange.end,
      isDark: isDark,
    ),
    barrierDismissible: true,
  );
}

class _RangePickerDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialStart;
  final DateTime initialEnd;
  final bool isDark;

  const _RangePickerDialog({
    required this.firstDate,
    required this.lastDate,
    required this.initialStart,
    required this.initialEnd,
    required this.isDark,
  });

  @override
  State<_RangePickerDialog> createState() => _RangePickerDialogState();
}

class _RangePickerDialogState extends State<_RangePickerDialog> {
  late DateTime _displayedMonth;
  DateTime? _start;
  DateTime? _end;

  static const _monthKeys = [
    'cal_month_1', 'cal_month_2', 'cal_month_3', 'cal_month_4',
    'cal_month_5', 'cal_month_6', 'cal_month_7', 'cal_month_8',
    'cal_month_9', 'cal_month_10', 'cal_month_11', 'cal_month_12',
  ];
  static const _weekdayKeys = [
    'cal_mon', 'cal_tue', 'cal_wed', 'cal_thu', 'cal_fri', 'cal_sat', 'cal_sun',
  ];

  @override
  void initState() {
    super.initState();
    _start = _dateOnly(widget.initialStart);
    _end = _dateOnly(widget.initialEnd);
    _displayedMonth = DateTime(widget.initialEnd.year, widget.initialEnd.month, 1);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _inBounds(DateTime d) =>
      !d.isBefore(widget.firstDate) && !d.isAfter(widget.lastDate);

  bool get _canGoPrev {
    final prevMonthEnd = DateTime(_displayedMonth.year, _displayedMonth.month, 0);
    return !prevMonthEnd.isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final nextMonthStart = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    return !nextMonthStart.isAfter(widget.lastDate);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textCol = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = _displayedMonth.weekday; // Monday=1 .. Sunday=7
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - totalCells % 7) % 7;

    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_displayedMonth.year, _displayedMonth.month, d),
      for (var i = 0; i < trailingBlanks; i++) null,
    ];

    final monthLabel = '${_monthKeys[_displayedMonth.month - 1].tr} ${_displayedMonth.year}';
    final rangeReady = _start != null && _end != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'cal_select_range'.tr,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textCol,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgBorder : const Color(0xFFEEF0F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close, size: 16,
                        color: isDark ? AppColors.textWhite : AppColors.textGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month navigation ───────────────────────────────────
            Row(
              children: [
                _NavArrow(
                  icon: Icons.chevron_left,
                  enabled: _canGoPrev,
                  isDark: isDark,
                  onTap: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textCol,
                      ),
                    ),
                  ),
                ),
                _NavArrow(
                  icon: Icons.chevron_right,
                  enabled: _canGoNext,
                  isDark: isDark,
                  onTap: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Weekday row ─────────────────────────────────────────
            Row(
              children: [
                for (final k in _weekdayKeys)
                  Expanded(
                    child: Center(
                      child: Text(
                        k.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Day grid ────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final day in cells)
                  day == null
                      ? const SizedBox.shrink()
                      : _DayCell(
                          day: day,
                          isDark: isDark,
                          enabled: _inBounds(day),
                          isStart: _start != null && day == _start,
                          isEnd: _end != null && day == _end,
                          inRange: _start != null && _end != null &&
                              day.isAfter(_start!) && day.isBefore(_end!),
                          isToday: day == _dateOnly(DateTime.now()),
                          onTap: () => _onDayTap(day),
                        ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Footer buttons ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('gen_cancel'.tr,
                        style: TextStyle(fontFamily: 'Gilroy', color: textCol)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: rangeReady
                        ? () => Get.back(result: DateTimeRange(start: _start!, end: _end!))
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary2,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('gen_save'.tr,
                        style: const TextStyle(
                            fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? (isDark ? AppColors.textWhite : const Color(0xFF0F172A))
                : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isDark;
  final bool enabled;
  final bool isStart;
  final bool isEnd;
  final bool inRange;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isDark,
    required this.enabled,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEdge = isStart || isEnd;
    final hasBand = inRange || isEdge;
    final textCol = !enabled
        ? AppColors.textDim
        : isEdge
            ? Colors.white
            : (isDark ? AppColors.textWhite : const Color(0xFF0F172A));

    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fills the whole cell edge-to-edge so adjacent in-range days
            // merge into one continuous strip instead of separate circles.
            if (hasBand) Container(color: AppColors.primary2.withAlpha(30)),
            Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEdge ? AppColors.primary2 : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isEdge
                      ? Border.all(color: AppColors.primary2, width: 1.4)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
                    color: textCol,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
