import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/shift_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

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
              const SizedBox(height: 24),
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'shift_opening_cash'.tr,
                  labelStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
                  hintText: '0.00',
                  filled: true,
                  fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                onSubmitted: (_) => _open(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _open,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green),
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_closedShift != null) {
      return _ShiftSummaryView(shift: _closedShift!);
    }

    final now = DateTime.now();
    final duration = now.difference(widget.shift.openedAt);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'shift_close'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$hours ${'shift_hours'.tr} $mins ${'shift_mins'.tr}',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 20,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoRow('shift_opened_at'.tr,
                  _fmtTime(widget.shift.openedAt)),
              _InfoRow('shift_opening_cash'.tr,
                  formatCurrency(widget.shift.openingCash)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'shift_closing_cash'.tr,
                  labelStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
                  hintText: '0.00',
                  filled: true,
                  fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text('gen_cancel'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _close,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              'shift_close'.tr,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
}

// ── Shift Summary ─────────────────────────────────────────────────────────────

class _ShiftSummaryView extends StatelessWidget {
  final Shift shift;
  const _ShiftSummaryView({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = (shift.closedAt ?? DateTime.now()).difference(shift.openedAt);
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
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary2),
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
          _StatLine('shift_opening_cash'.tr,
              formatCurrency(shift.openingCash)),
          const SizedBox(height: 4),
          _StatLine('shift_closing_cash'.tr,
              formatCurrency(shift.closingCash ?? 0)),
          const SizedBox(height: 4),
          _StatLine(
            'shift_cash_diff'.tr,
            formatCurrency(
                (shift.closingCash ?? 0) - shift.openingCash - shift.totalCash),
            color: ((shift.closingCash ?? 0) - shift.openingCash - shift.totalCash)
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
