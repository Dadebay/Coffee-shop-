import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../constants/color_constants.dart';

class TouchNumpad extends StatelessWidget {
  final Function(String) onTap;
  final Color accentColor;
  final bool isDark;

  const TouchNumpad({
    super.key,
    required this.onTap,
    this.accentColor = AppColors.primary2,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = isDark ? AppColors.bgCard : const Color(0xFFF0F0F5);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isBack = key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onTap(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      height: 52,
                      decoration: BoxDecoration(
                        color: isBack
                            ? AppColors.red.withAlpha(20)
                            : btnColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBack
                              ? AppColors.red.withAlpha(60)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: isBack
                            ? const HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete02,
                                size: 20,
                                color: AppColors.red,
                              )
                            : Text(
                                key,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
