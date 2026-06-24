import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getReportCards(),
              builder: (context, snapshot) {
                final reports = snapshot.data ?? const <Map<String, dynamic>>[];
                return Padding(
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
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (snapshot.connectionState != ConnectionState.waiting)
                          ...reports.map((card) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ReportCard(
                                  title: '${card['title'] ?? '-'}',
                                  description: '${card['description'] ?? '-'}',
                                  icon: _reportIcon('${card['icon'] ?? ''}'),
                                ),
                              )),
                      ],
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

IconData _reportIcon(String iconName) {
  switch (iconName) {
    case 'bar_chart':
      return Icons.bar_chart;
    case 'assessment':
      return Icons.assessment;
    case 'medication':
      return Icons.medication;
    default:
      return Icons.description;
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
