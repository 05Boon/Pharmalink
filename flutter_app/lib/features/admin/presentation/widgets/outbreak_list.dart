import 'package:flutter/material.dart';
import '../../../../models/outbreak_alert.dart';

class OutbreakList extends StatelessWidget {
  final List<OutbreakAlert> alerts;

  const OutbreakList({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 48),
            SizedBox(height: 16),
            Text(
              'System Monitoring Active:\nNo localized outbreaks detected',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF0F6E56), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      separatorBuilder: (context, idx) => const Divider(color: Color(0xFFE8E6DF), height: 16),
      itemBuilder: (context, idx) {
        final a = alerts[idx];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFB91C1C),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${a.incidentCount}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.shortageReason,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC07000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Category: ${a.drugCategory}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5F5E5A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

