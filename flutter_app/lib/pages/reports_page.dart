import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/mock_data_store.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Reports', path: '/admin/reports', active: true),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFB4B2A9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...MockDataStore.reportCards.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final card = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: idx == MockDataStore.reportCards.length - 1
                                ? 0
                                : 8),
                        child: _ReportCard(
                          title: card['title'] ?? '-',
                          description: card['description'] ?? '-',
                          icon: MockDataStore.reportIcon(card['icon'] ?? ''),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFEA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: Color(0xFF5F5E5A)),
        ],
      ),
    );
  }
}
