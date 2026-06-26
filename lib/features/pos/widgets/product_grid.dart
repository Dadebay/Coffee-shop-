import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

class _ProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product) onTap;

  const _ProductCard({required this.product, required this.onTap});

  double get _price {
    if (product.discountType == 'percentage') {
      return (product.price - product.price * product.discount / 100)
          .clamp(0, double.infinity);
    }
    return (product.price - product.discount).clamp(0, double.infinity);
  }

  bool get _outOfStock => product.quantity <= 0;
  bool get _hasImage =>
      product.imagePath != null && product.imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _outOfStock ? null : () => onTap(product),
      child: AnimatedOpacity(
        opacity: _outOfStock ? 0.38 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: image or accent bar
              _hasImage
                  ? _ImageHeader(imagePath: product.imagePath!)
                  : Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.primary2,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                    ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasImage)
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.local_cafe_outlined,
                              size: 38,
                              color: AppColors.primary2.withAlpha(160),
                            ),
                          ),
                        ),
                      if (_hasImage) const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatCurrency(_price),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: AppColors.primary2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (product.discount > 0)
                                Text(
                                  formatCurrency(product.price),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    color: AppColors.textDim,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_outOfStock
                                      ? AppColors.red
                                      : AppColors.green)
                                  .withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _outOfStock ? 'Yok' : '${product.quantity}',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _outOfStock
                                    ? AppColors.red
                                    : AppColors.green,
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
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final String imagePath;
  const _ImageHeader({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: SizedBox(
        height: 90,
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
        child: const Icon(Icons.broken_image_outlined,
            size: 28, color: AppColors.textDim),
      );
}
