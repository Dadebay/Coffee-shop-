import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/color_constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bgBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kassa',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              const Text(
                'Coffee Shop POS',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => _PinDot(filled: i < auth.pin.value.length)),
                  )),
              const SizedBox(height: 10),
              Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: auth.error.value.isEmpty
                        ? const SizedBox(height: 18)
                        : Text(
                            auth.error.value,
                            key: const ValueKey('err'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              color: AppColors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  )),
              const SizedBox(height: 20),

              // Numpad
              _Numpad(
                onDigit: auth.addDigit,
                onBackspace: auth.backspace,
                onClear: auth.clearPin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  const _PinDot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary2 : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary2 : AppColors.bgBorder,
          width: 2,
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const _Numpad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .map((k) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _NumKey(
                              label: k,
                              isAction: k == 'C' || k == '⌫',
                              onTap: () {
                                if (k == '⌫')
                                  onBackspace();
                                else if (k == 'C')
                                  onClear();
                                else
                                  onDigit(k);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;

  const _NumKey({required this.label, required this.onTap, this.isAction = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction ? Colors.transparent : AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withAlpha(40),
        child: Container(
          width: 74,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isAction ? AppColors.textGrey : AppColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
