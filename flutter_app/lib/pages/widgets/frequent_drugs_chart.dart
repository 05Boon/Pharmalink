import 'package:flutter/material.dart';

class FrequentDrugsChart extends StatelessWidget {
  final List<Map<String, dynamic>> drugs;

  const FrequentDrugsChart({super.key, required this.drugs});

  @override
  Widget build(BuildContext context) {
    if (drugs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No historical drug requests found.',
          style: TextStyle(color: Color(0xFF5F5E5A)),
        ),
      );
    }

    final double maxRequests = drugs.fold(0.0, (max, item) {
      final reqCount = (item['request_count'] as num).toDouble();
      return reqCount > max ? reqCount : max;
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Most Frequently Requested Drugs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 24),
          ...drugs.map((drug) {
            final drugName = drug['drug_name'].toString();
            final count = (drug['request_count'] as num).toDouble();
            final widthFactor = maxRequests == 0 ? 0.0 : count / maxRequests;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      drugName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A1A18),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Max bar width leaves 40 pixels for the number label
                        final maxBarWidth = constraints.maxWidth - 40;
                        final barWidth = maxBarWidth * widthFactor;
                        return Row(
                          children: [
                            Container(
                              height: 24,
                              width: barWidth > 0 ? barWidth : 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F6E56),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5F5E5A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
