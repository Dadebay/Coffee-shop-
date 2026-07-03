import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/shift_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/numpad.dart';

// ── Open Shift Dialog ─────────────────────────────────────────────────────────

class OpenShiftDialog extends StatefulWidget {
  const OpenShiftDialog({super.key});

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _loading = true);
    final amount = double.tryParse(_ctrl.text) ?? 0;
    await ShiftController.to.openShift(amount);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    color: AppColors.green,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'shift_open'.tr,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'shift_open_desc'.tr,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              NumPadWidget(
                controller: _ctrl,
                label: 'shift_opening_cash'.tr,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _open,
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.green),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'shift_start'.tr,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Close Shift Dialog ────────────────────────────────────────────────────────

class CloseShiftDialog extends StatefulWidget {
  final Shift shift;
  const CloseShiftDialog({super.key, required this.shift});

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  Shift? _closedShift;
  late Timer _timer;
  late DateTime _now;
  late Worker _userWatch;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Auto-close if the logged-in user changes
    _userWatch = ever(AuthController.to.currentUser, (_) {
      if (mounted) Get.back();
    });
  }

  Future<void> _close() async {
    setState(() => _loading = true);
    final amount = double.tryParse(_ctrl.text) ?? 0;
    final closed = await ShiftController.to.closeShift(amount);
    if (mounted) {
      setState(() {
        _loading = false;
        _closedShift = closed;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _userWatch.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_closedShift != null) {
      return _ShiftSummaryView(shift: _closedShift!);
    }

    final duration = _now.difference(widget.shift.openedAt);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    const targetSeconds = 8 * 3600;
    final progress = (duration.inSeconds / targetSeconds).clamp(0.0, 1.0);
    final isOvertime = duration.inSeconds > targetSeconds;

    final openTimeStr = _fmtTime(widget.shift.openedAt);
    final targetTimeStr =
        _fmtTime(widget.shift.openedAt.add(const Duration(hours: 8)));
    final nowTimeStr = _fmtTime(_now);

    final cardBg = isDark ? AppColors.bgCard : const Color(0xFFF8FAFF);
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final workerName = AuthController.to.currentUser.value?.name ?? '—';

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: MediaQuery.of(context).size.height - 80,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          color: AppColors.red,
                          size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('shift_close'.tr,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      Row(
                        children: [
                          const HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: 12,
                              color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(workerName,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.bgBorder
                            : const Color(0xFFEEF0F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 14,
                              color: AppColors.textGrey)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Time progress card ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    // Açılış → Şu an → Hedef
                    Row(
                      children: [
                        // Açılış
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(openTimeStr,
                                style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: textColor)),
                            Text('shift_opened_at'.tr,
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 10,
                                    color: AppColors.textGrey)),
                          ],
                        ),
                        const Spacer(),
                        // Geçen süre — ortada
                        Column(
                          children: [
                            Text(
                              '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: isOvertime
                                    ? AppColors.red
                                    : AppColors.primary2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isOvertime
                                        ? AppColors.red
                                        : AppColors.primary2)
                                    .withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOvertime
                                    ? 'Mesai aşıldı!'
                                    : '${'shift_hours'.tr} 8:00',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOvertime
                                      ? AppColors.red
                                      : AppColors.primary2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Hedef bitiş
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(targetTimeStr,
                                style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: textColor)),
                            Text('8 saat',
                                style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 10,
                                    color: AppColors.textGrey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? AppColors.bgBorder
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(
                            isOvertime ? AppColors.red : AppColors.primary2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(openTimeStr,
                            style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 10,
                                color: AppColors.textDim)),
                        Text(nowTimeStr,
                            style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOvertime
                                    ? AppColors.red
                                    : AppColors.primary2)),
                        Text(targetTimeStr,
                            style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 10,
                                color: AppColors.textDim)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Info rows ───────────────────────────────────────────
              _InfoRow('shift_opened_at'.tr,
                  '${_fmtDate(widget.shift.openedAt)}  $openTimeStr'),
              _InfoRow('shift_opening_cash'.tr,
                  formatCurrency(widget.shift.openingCash)),
              const SizedBox(height: 14),

              // ── Closing cash input ──────────────────────────────────
              NumPadWidget(
                controller: _ctrl,
                label: 'shift_closing_cash'.tr,
              ),
              const SizedBox(height: 16),

              // ── Buttons ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('gen_cancel'.tr,
                          style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _close,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('shift_close'.tr,
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Shift Summary ─────────────────────────────────────────────────────────────

class _ShiftSummaryView extends StatelessWidget {
  final Shift shift;
  const _ShiftSummaryView({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration =
        (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    color: AppColors.green,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'shift_closed'.tr,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Text(
                '$h ${'shift_hours'.tr} $m ${'shift_mins'.tr}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              _SummaryCard(shift: shift),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Get.back(),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary2),
                  child: Text(
                    'gen_close'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Shift shift;
  const _SummaryCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _StatLine('shift_orders'.tr, '${shift.orderCount}',
              color: AppColors.primary2),
          const SizedBox(height: 8),
          _StatLine('rep_revenue'.tr, formatCurrency(shift.totalRevenue),
              color: AppColors.green, bold: true),
          const SizedBox(height: 8),
          _StatLine('pay_method_cash'.tr, formatCurrency(shift.totalCash)),
          const SizedBox(height: 4),
          _StatLine('pay_method_card'.tr, formatCurrency(shift.totalCard)),
          Divider(color: borderColor, height: 20),
          _StatLine('shift_opening_cash'.tr, formatCurrency(shift.openingCash)),
          const SizedBox(height: 4),
          _StatLine(
              'shift_closing_cash'.tr, formatCurrency(shift.closingCash ?? 0)),
          const SizedBox(height: 4),
          _StatLine(
            'shift_cash_diff'.tr,
            formatCurrency(
                (shift.closingCash ?? 0) - shift.openingCash - shift.totalCash),
            color:
                ((shift.closingCash ?? 0) - shift.openingCash - shift.totalCash)
                            .abs() <
                        0.01
                    ? AppColors.green
                    : AppColors.red,
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  const _StatLine(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: AppColors.textGrey,
              fontSize: 13,
            )),
        Text(value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 16 : 13,
              color: color,
            )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                color: AppColors.textGrey,
                fontSize: 13,
              )),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}
