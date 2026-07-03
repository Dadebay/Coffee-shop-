import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/color_constants.dart';

class ProductThumb extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final double size;

  const ProductThumb({
    super.key,
    required this.imagePath,
    required this.isDark,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(
            color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    final dimColor = isDark ? AppColors.textDim : const Color(0xFFB0B8C8);
    if (imagePath == null || imagePath!.isEmpty) {
      return Center(
        child: HugeIcon(
            icon: HugeIcons.strokeRoundedCoffee01,
            size: size * 0.5,
            color: dimColor),
      );
    }
    if (kIsWeb || imagePath!.startsWith('data:')) {
      try {
        final comma = imagePath!.indexOf(',');
        if (comma < 0) throw Exception();
        final bytes = base64Decode(imagePath!.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedImageNotFound01,
              size: size * 0.5,
              color: dimColor),
        );
      }
    }
    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            size: size * 0.5,
            color: dimColor),
      ),
    );
  }
}
