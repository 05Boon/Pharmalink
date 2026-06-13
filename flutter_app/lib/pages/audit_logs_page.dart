import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = [
      {'time': '2026-06-03 10:23', 'user': 'admin@system', 'action': 'Approved pharmacy: Green Leaf'},
      {'time': '2026-06-03 09:15', 'user': 'john@city.com', 'action': 'Created drug query'},
      {'time': '2026-06-03 08:42', 'user': 'admin@system', 'action': 'Generated monthly report'},
      {'time': '2026-06-02 16:30', 'user': 'sarah@health.com', 'action': 'Accepted share request'},
    ];

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Logs', path: '/admin/logs', active: true),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: SingleChildScrollView(
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
                      'Audit logs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...logs.map((log) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE8E6DF)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['action']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log['user']} • ${log['time']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5F5E5A),
                                ),
                              ),
                            ],
                          ),
                        )),
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
