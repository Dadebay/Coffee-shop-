import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/color_constants.dart';

/// Opens the numpad dialog and updates [controller] on confirm.
/// Returns the entered string, or null if cancelled.
Future<String?> showNumPad(
  BuildContext context,
  TextEditingController controller, {
  String? label,
  String? suffix,
  bool allowDecimal = true,
  bool allowPercent = false,
}) async {
  final result = await Get.dialog<String>(
    _NumPadDialog(
      initial: controller.text,
      label: label,
      suffix: suffix,
      allowDecimal: allowDecimal,
      allowPercent: allowPercent,
    ),
    barrierDismissible: true,
  );
  if (result != null) {
    controller.text = result;
    controller.selection =
        TextSelection.collapsed(offset: result.length);
  }
  return result;
}

// ─── Dialog ─────────────────────────────────────────────────────────────────

class _NumPadDialog extends StatefulWidget {
  final String initial;
  final String? label;
  final String? suffix;
  final bool allowDecimal;
  final bool allowPercent;

  const _NumPadDialog({
    required this.initial,
    this.label,
    this.suffix,
    this.allowDecimal = true,
    this.allowPercent = false,
  });

  @override
  State<_NumPadDialog> createState() => _NumPadDialogState();
}

class _NumPadDialogState extends State<_NumPadDialog> {
  late String _val;

  @override
  void initState() {
    super.initState();
    _val = widget.initial.isEmpty ? '' : widget.initial;
  }

  void _press(String key) {
    setState(() {
      switch (key) {
        case '⌫':
          if (_val.isNotEmpty) _val = _val.substring(0, _val.length - 1);
        case 'C':
          _val = '';
        case '.':
          if (!_val.contains('.') && !_val.contains('%')) _val += '.';
        case '%':
          // % goes at the end, only once, no decimal after it
          final base = _val.replaceAll('%', '');
          _val = '$base%';
        default:
          // Don't add digits after %
          if (_val.endsWith('%')) return;
          // Limit to reasonable length
          if (_val.length >= 10) return;
          _val += key;
      }
    });
  }

  void _confirm() => Get.back(result: _val);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final surfaceBg = isDark ? AppColors.bgSurface : const Color(0xFFF4F6FB);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final displayValue = _val.isEmpty ? '0' : _val;
    final hasSuffix = widget.suffix != null && widget.suffix!.isNotEmpty;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Display ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.label != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        widget.label!,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            displayValue,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      if (hasSuffix) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.suffix!,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Keys ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _row(['7', '8', '9'], isDark, textColor),
                  const SizedBox(height: 8),
                  _row(['4', '5', '6'], isDark, textColor),
                  const SizedBox(height: 8),
                  _row(['1', '2', '3'], isDark, textColor),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (widget.allowPercent)
                      _key('%', isDark, textColor, flex: 1, color: AppColors.orange)
                    else if (widget.allowDecimal)
                      _key('.', isDark, textColor, flex: 1)
                    else
                      _key('C', isDark, textColor, flex: 1, color: AppColors.red.withAlpha(180)),
                    const SizedBox(width: 8),
                    _key('0', isDark, textColor, flex: 1),
                    const SizedBox(width: 8),
                    _key('⌫', isDark, textColor,
                        flex: 1, color: AppColors.red.withAlpha(200), isIcon: true),
                  ]),
                  if (widget.allowDecimal && widget.allowPercent) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      _key('.', isDark, textColor, flex: 1),
                      const SizedBox(width: 8),
                      _key('C', isDark, textColor, flex: 2, color: AppColors.textGrey),
                    ]),
                  ],
                ],
              ),
            ),

            // ── OK ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'numpad_confirm'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys, bool isDark, Color textColor) {
    return Row(
      children: keys.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
            child: _keyBody(e.value, isDark, textColor),
          ),
        );
      }).toList(),
    );
  }

  // Returns a plain widget (no Expanded) — callers add Expanded themselves
  Widget _keyBody(String label, bool isDark, Color textColor, {Color? color, bool isIcon = false}) {
    final bg = isDark ? AppColors.bgSurface : const Color(0xFFF0F2F8);
    final fgColor = color ?? textColor;
    return GestureDetector(
      onTap: () => _press(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 56,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: isIcon
              ? Icon(Icons.backspace_outlined, color: fgColor, size: 22)
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: label.length > 1 ? 16 : 22,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
        ),
      ),
    );
  }

  // Returns Expanded wrapping a key — for use directly inside Row
  Widget _key(String label, bool isDark, Color textColor, {int flex = 1, Color? color, bool isIcon = false}) {
    return Expanded(
      flex: flex,
      child: _keyBody(label, isDark, textColor, color: color, isIcon: isIcon),
    );
  }
}

// ─── NumPadField — drop-in replacement for numeric TextFormField ─────────────

class NumPadField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool allowDecimal;
  final bool allowPercent;
  final String? Function(String?)? validator;
  final String? numpadLabel;
  final String? numpadSuffix;

  const NumPadField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.allowDecimal = true,
    this.allowPercent = false,
    this.validator,
    this.numpadLabel,
    this.numpadSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showNumPad(
        context,
        controller,
        label: numpadLabel ?? decoration.labelText ?? decoration.hintText,
        suffix: numpadSuffix,
        allowDecimal: allowDecimal,
        allowPercent: allowPercent,
      ),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          validator: validator,
          style: style,
          decoration: decoration,
        ),
      ),
    );
  }
}
