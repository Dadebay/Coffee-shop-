import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/product_thumb.dart';

// ─── Table ────────────────────────────────────────────────────────────────────

class ProductTable extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;
  final List<Unit> units;
  final Map<int, int> maxProducible;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;

  const ProductTable({
    super.key,
    required this.products,
    required this.categories,
    required this.units,
    required this.maxProducible,
    required this.onEdit,
    required this.onDelete,
  });

  String _catName(int? id) => id == null
      ? '—'
      : categories.firstWhereOrNull((c) => c.id == id)?.name ?? '—';

  String _unitShort(int? id) => id == null
      ? ''
      : units.firstWhereOrNull((u) => u.id == id)?.shortName ?? '';

  double _discounted(Product p) {
    if (p.discountType == 'percentage') {
      return (p.price - p.price * p.discount / 100).clamp(0, double.infinity);
    }
    return (p.price - p.discount).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final hoverColor = isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);
    final headerBg = isDark ? AppColors.bgSurface : const Color(0xFFF4F6FB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 52),
                Expanded(flex: 3, child: ProdTH('prod_name'.tr)),
                Expanded(flex: 2, child: ProdTH('prod_category'.tr)),
                Expanded(flex: 2, child: ProdTH('prod_price'.tr)),
                Expanded(flex: 2, child: ProdTH('prod_cost'.tr)),
                Expanded(flex: 2, child: ProdTH('prod_profit'.tr)),
                Expanded(flex: 1, child: ProdTH('prod_qty'.tr)),
                Expanded(flex: 1, child: ProdTH('gen_status'.tr)),
                SizedBox(width: 80, child: Center(child: ProdTH('gen_action'.tr))),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                final discPrice = _discounted(p);
                final cost =
                    p.useRecipeCost ? p.recipeCalculatedCost : p.purchasePrice;
                final profit = discPrice - cost;
                final unit = _unitShort(p.unitId);
                final isLast = i == products.length - 1;
                final textColor =
                    isDark ? AppColors.textWhite : const Color(0xFF0F172A);
                final subColor =
                    isDark ? AppColors.textDim : const Color(0xFF94A3B8);
                final maxCount = maxProducible[p.id] ?? -1;

                return Container(
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(color: borderColor, width: 0.5))
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onEdit(p),
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(16))
                          : null,
                      hoverColor: hoverColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            ProductThumb(
                                imagePath: p.imagePath, isDark: isDark),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: textColor),
                                      overflow: TextOverflow.ellipsis),
                                  Row(
                                    children: [
                                      Text('SKU: ${p.sku}',
                                          style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 11,
                                              color: subColor)),
                                      if (p.expireDate != null) ...[
                                        const SizedBox(width: 8),
                                        ProductExpiryBadge(date: p.expireDate!),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(_catName(p.categoryId),
                                  style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textGrey
                                          : const Color(0xFF64748B))),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formatCurrency(discPrice),
                                      style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.primary2)),
                                  if (p.discount > 0)
                                    Text(formatCurrency(p.price),
                                        style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 10,
                                            color: subColor,
                                            decoration:
                                                TextDecoration.lineThrough)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(formatCurrency(cost),
                                  style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textGrey
                                          : const Color(0xFF64748B))),
                            ),
                            Expanded(
                                flex: 2, child: ProfitBadge(profit: profit)),
                            Expanded(
                              flex: 1,
                              child: Text(
                                maxCount >= 0
                                    ? '$maxCount${unit.isNotEmpty ? ' $unit' : ''}'
                                    : '—',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: maxCount == 0
                                      ? AppColors.red
                                      : maxCount > 0
                                          ? textColor
                                          : AppColors.textDim,
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 1, child: StatusBadge(active: p.status)),
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ProdIconBtn(
                                      icon: HugeIcons.strokeRoundedPencilEdit01,
                                      color: AppColors.primary2,
                                      onTap: () => onEdit(p)),
                                  const SizedBox(width: 4),
                                  ProdIconBtn(
                                      icon: HugeIcons.strokeRoundedDelete02,
                                      color: AppColors.red,
                                      onTap: () => onDelete(p)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class ProdTH extends StatelessWidget {
  final String text;
  const ProdTH(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.5));
}

class ProdIconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const ProdIconBtn(
      {super.key, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
        child: HugeIcon(icon: icon, size: 15, color: color),
      ),
    );
  }
}

class ProfitBadge extends StatelessWidget {
  final double profit;
  const ProfitBadge({super.key, required this.profit});

  @override
  Widget build(BuildContext context) {
    final color = profit >= 0 ? AppColors.green : AppColors.red;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          '${profit >= 0 ? '+' : ''}${formatCurrency(profit)}',
          style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool active;
  const StatusBadge({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (active ? AppColors.green : AppColors.textDim).withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          active ? 'prod_status_active'.tr : 'prod_status_inactive'.tr,
          style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.green : AppColors.textDim),
        ),
      ),
    );
  }
}

class ProdEmptyState extends StatelessWidget {
  const ProdEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              size: 54,
              color: isDark
                  ? AppColors.textDim.withAlpha(120)
                  : const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text('prod_empty'.tr,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  color:
                      isDark ? AppColors.textGrey : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ─── Expiry Badge ─────────────────────────────────────────────────────────────

class ProductExpiryBadge extends StatelessWidget {
  final DateTime date;
  const ProductExpiryBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = date.isBefore(now);
    final isExpiringSoon =
        !isExpired && date.isBefore(now.add(const Duration(days: 7)));

    if (!isExpired && !isExpiringSoon) {
      return const SizedBox.shrink();
    } // No badge if safe

    final color = isExpired ? AppColors.red : AppColors.orange;
    final text = isExpired
        ? 'exp_expired'.tr
        : 'exp_warning'
            .tr
            .replaceAll('{days}', date.difference(now).inDays.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 50 : 20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
