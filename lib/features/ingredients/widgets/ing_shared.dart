import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/color_constants.dart';

// ─── Shared dialog shell ──────────────────────────────────────────────────────

class IngDialogShell extends StatelessWidget {
  final String title;
  final Widget content;
  final double width;
  const IngDialogShell(
      {super.key,
      required this.title,
      required this.content,
      this.width = 420});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedWarehouse,
                      size: 18,
                      color: AppColors.primary2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Divider(color: borderColor, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────

class IngField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool numeric;
  final String? Function(String?)? validator;
  final String? suffix;

  const IngField({
    super.key,
    required this.controller,
    required this.label,
    this.numeric = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontFamily: 'Gilroy',
      fontSize: 14,
      color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
    );
    final dec = InputDecoration(
      labelText: label,
      suffixText: suffix,
      labelStyle: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          color: isDark ? AppColors.textGrey : const Color(0xFF64748B)),
      filled: true,
      fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color:
                  isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color:
                  isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary2, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red)),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      style: textStyle,
      decoration: dec,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
    );
  }
}

// ─── Dialog action buttons ────────────────────────────────────────────────────

class IngDialogActions extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool loading;
  const IngDialogActions({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: Get.back,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: BorderSide(color: Colors.grey.withAlpha(60)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                  fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary2,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    confirmLabel,
                    style: const TextStyle(
                        fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
