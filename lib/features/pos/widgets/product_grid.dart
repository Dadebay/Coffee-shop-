import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onTap;

  const ProductGrid({super.key, required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(product: products[i], onTap: onTap),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final void Function(Product) onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hov = false;

  double get _price {
    final p = widget.product;
    if (p.discountType == 'percentage') {
      return (p.price - p.price * p.discount / 100).clamp(0, double.infinity);
    }
    return (p.price - p.discount).clamp(0, double.infinity);
  }

  bool get _outOfStock => false;
  bool get _hasImage =>
      widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.product;
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = _hov && !_outOfStock
        ? AppColors.primary2.withAlpha(120)
        : (isDark ? AppColors.bgBorder : const Color(0xFFE4E7F0));
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: _outOfStock ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _outOfStock ? null : () => widget.onTap(p),
        child: AnimatedOpacity(
          opacity: _outOfStock ? 0.42 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: _hov ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 0 : (_hov ? 10 : 5)),
                  blurRadius: _hov ? 14 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image or icon area ──
                _hasImage
                    ? _ImageHeader(imagePath: p.imagePath!)
                    : _IconHeader(isDark: isDark),

                // ── Info ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textColor,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.discount > 0)
                                    Text(
                                      formatCurrency(p.price),
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        color: AppColors.textDim,
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    formatCurrency(_price),
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      color: AppColors.primary2,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stock badge
                            if (p.quantity > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withAlpha(isDark ? 30 : 18),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: AppColors.green.withAlpha(60)),
                                ),
                                child: Text(
                                  '${p.quantity}',
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconHeader extends StatelessWidget {
  final bool isDark;
  const _IconHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withAlpha(40), AppColors.primary2.withAlpha(20)]
              : [const Color(0xFFEEF3FF), const Color(0xFFDDE8FF)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedCoffee01,
          size: 40,
          color: AppColors.primary2.withAlpha(isDark ? 200 : 160),
        ),
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final String imagePath;
  const _ImageHeader({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb || imagePath.startsWith('data:')) {
      try {
        final comma = imagePath.indexOf(',');
        if (comma < 0) throw Exception();
        final bytes = base64Decode(imagePath.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _fallback();
      }
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.bgSurface,
        child: const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01,
            size: 28, color: AppColors.textDim),
      );
}
