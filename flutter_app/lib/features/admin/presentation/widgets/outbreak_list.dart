import 'package:flutter/material.dart';
import '../../models/outbreak_analytic_model.dart';

class OutbreakList extends StatelessWidget {
  final List<OutbreakAnalytic> outbreaks;
  final Function(OutbreakAnalytic) onItemTapped;

  const OutbreakList({
    super.key,
    required this.outbreaks,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (outbreaks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No outbreak clusters detected in this timeframe.',
            style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: outbreaks.length,
      separatorBuilder: (context, idx) => const Divider(color: Color(0xFFE8E6DF)),
      itemBuilder: (context, idx) {
        final o = outbreaks[idx];
        return InkWell(
          onTap: () => onItemTapped(o),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${o.requestFrequency}x',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC07000),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.requestedDrug,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Centroid: [${o.centroidLatitude.toStringAsFixed(4)}, ${o.centroidLongitude.toStringAsFixed(4)}]',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 14, color: Color(0xFFB4B2A9)),
              ],
            ),
          ),
        );
      },
    );
  }
}
