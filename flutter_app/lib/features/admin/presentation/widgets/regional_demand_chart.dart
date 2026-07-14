import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RegionalDemandChart extends StatelessWidget {
  final List<Map<String, dynamic>> demandData;

  const RegionalDemandChart({
    super.key,
    required this.demandData,
  });

  @override
  Widget build(BuildContext context) {
    if (demandData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x80B4B2A9)),
        ),
        child: const Center(
          child: Text(
            'No regional demand data available.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F5E5A)),
          ),
        ),
      );
    }

    // Limit to top 5 regions to keep chart clean
    final displayData = demandData.take(5).toList();

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x80B4B2A9)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regional Demand Anomalies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Top requested drug by region (%)',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF5F5E5A),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF1A1A18),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = displayData[group.x];
                      return BarTooltipItem(
                        '${item['top_drug']}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${item['percentage']}% of region total',
                            style: const TextStyle(
                              color: Color(0xFFE2F3EE),
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= displayData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${displayData[index]['area_label']}',
                            style: const TextStyle(
                              color: Color(0xFF1A1A18),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF5F5E5A),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Color(0x80B4B2A9), width: 1),
                    left: BorderSide(color: Color(0x80B4B2A9), width: 1),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0x30B4B2A9),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: displayData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final percentage = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        color: const Color(0xFF0F6E56),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
