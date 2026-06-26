import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/stock_report_controller.dart';
import '../../core/constants/color_constants.dart';
import '../../data/database/app_database.dart';

class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => StockReportController());
    final ctrl = StockReportController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFF5F5F7);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(context, isDark, textColor),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: CustomScrollView(
                  slivers: [
                  SliverToBoxAdapter(child: _buildSummaryGrid(ctrl, isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _buildFilterTabs(ctrl, isDark)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildProductsList(ctrl, isDark),
                  if (ctrl.criticalIngredients.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    SliverToBoxAdapter(
                      child: Text(
                        'stock_rep_critical'.tr,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildCriticalIngredientsList(ctrl, isDark),
                  ]
                ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedChartBarLine,
            size: 22,
            color: AppColors.primary2,
          ),
          const SizedBox(width: 12),
          Text(
            'stock_rep_title'.tr,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          // Placeholder for Excel Export (Feature 7)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.green.withAlpha(50)),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 16,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'stock_rep_export'.tr,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(StockReportController ctrl, bool isDark) {
    final s = ctrl.summary;
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    String formatMoney(double val) => val.toStringAsFixed(0).replaceAllMapped(formatter, (m) => ' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _SummaryCard(
              title: 'stock_rep_products'.tr,
              value: '${s['productCount'] ?? 0}',
              icon: HugeIcons.strokeRoundedPackage,
              color: AppColors.primary2,
              isDark: isDark,
            ),
            _SummaryCard(
              title: 'stock_rep_total_value'.tr,
              value: '${formatMoney(s['totalProductValue'] ?? 0)} TMT',
              icon: HugeIcons.strokeRoundedWallet02,
              color: AppColors.green,
              isDark: isDark,
            ),
            _SummaryCard(
              title: 'stock_rep_zero'.tr,
              value: '${s['zeroStock'] ?? 0}',
              icon: HugeIcons.strokeRoundedPackageRemove,
              color: AppColors.orange,
              isDark: isDark,
            ),
            _SummaryCard(
              title: 'stock_rep_critical'.tr,
              value: '${s['criticalIngredients'] ?? 0}',
              icon: HugeIcons.strokeRoundedAlert02,
              color: AppColors.red,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs(StockReportController ctrl, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'rep_all'.tr, 'icon': HugeIcons.strokeRoundedPackageSearch},
      {'key': 'zero', 'label': 'stock_rep_zero'.tr, 'icon': HugeIcons.strokeRoundedPackageRemove},
      {'key': 'expiring', 'label': 'stock_rep_expiring'.tr, 'icon': HugeIcons.strokeRoundedClock01},
      {'key': 'expired', 'label': 'stock_rep_expired'.tr, 'icon': HugeIcons.strokeRoundedCancel01},
    ];

    return Row(
      children: filters.map((f) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Obx(() {
            final selected = ctrl.filterType.value == f['key'];
            return GestureDetector(
              onTap: () => ctrl.setFilter(f['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary2 : (isDark ? AppColors.bgCard : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary2 : (isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: AppColors.primary2.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: f['icon'] as List<List<dynamic>>,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : (isDark ? AppColors.textWhite : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      }).toList(),
    );
  }

  Widget _buildProductsList(StockReportController ctrl, bool isDark) {
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return Obx(() {
      final list = ctrl.filteredProducts;
      if (list.isEmpty) {
        return SliverToBoxAdapter(
          child: Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'pos_no_products'.tr,
              style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.textGrey),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              p.sku,
                              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: AppColors.textGrey),
                            ),
                            const SizedBox(width: 12),
                            if (p.expireDate != null)
                              _buildExpiryBadge(p.expireDate!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.quantity}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: p.quantity == 0 ? AppColors.red : textColor,
                        ),
                      ),
                      Text(
                        'stock_qty'.tr,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: list.length,
        ),
      );
    });
  }

  Widget _buildCriticalIngredientsList(StockReportController ctrl, bool isDark) {
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ing = ctrl.criticalIngredients[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha(isDark ? 15 : 5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.red.withAlpha(50)),
            ),
            child: Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 24, color: AppColors.red),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ing.name,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'ing_min_stock'.tr}: ${ing.minStock} ${ing.unit}',
                        style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: AppColors.red),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${ing.stock.toStringAsFixed(2)} ${ing.unit}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: ctrl.criticalIngredients.length,
      ),
    );
  }

  Widget _buildExpiryBadge(DateTime expiry) {
    final now = DateTime.now();
    final in7Days = now.add(const Duration(days: 7));
    
    Color color;
    String text;
    
    if (expiry.isBefore(now)) {
      color = AppColors.red;
      text = 'exp_expired'.tr;
    } else if (expiry.isBefore(in7Days)) {
      color = AppColors.orange;
      final days = expiry.difference(now).inDays;
      text = 'exp_warning'.tr.replaceAll('{days}', '$days');
    } else {
      return const SizedBox.shrink(); // Normal, no badge needed
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 24, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
