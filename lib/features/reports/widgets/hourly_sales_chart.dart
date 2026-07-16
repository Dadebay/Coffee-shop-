import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/utils/formatters.dart';

// ── Hourly sales chart ─────────────────────────────────────────────────────────

class HourlySalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;
  const HourlySalesChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    if (data.isEmpty) return const SizedBox();

    double maxRev = 0;
    for (var d in data) {
      if ((d['revenue'] as double) > maxRev) maxRev = d['revenue'] as double;
    }
    if (maxRev == 0) maxRev = 100;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('rep_hourly_sales'.tr,
              style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRev * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    formatCurrency(rod.toY),
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy'),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 3 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${value.toInt()}:00',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textGrey
                                    : AppColors.textDim,
                                fontSize: 10,
                                fontFamily: 'Gilroy')),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxRev / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data
                  .map((d) => BarChartGroupData(
                        x: d['hour'] as int,
                        barRods: [
                          BarChartRodData(
                              toY: d['revenue'] as double,
                              color: AppColors.primary2,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)))
                        ],
                      ))
                  .toList(),
            )),
          ),
        ],
      ),
    );
  }
}

