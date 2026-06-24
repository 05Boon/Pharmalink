import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Logs', path: '/admin/logs', active: true),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getAuditLogs(),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? const <Map<String, dynamic>>[];

                return SingleChildScrollView(
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
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (snapshot.connectionState != ConnectionState.waiting)
                          ...logs.map((log) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: Color(0xFFE8E6DF)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log['action'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${log['user'] ?? '-'} • ${log['time'] ?? log['created_at'] ?? '-'}',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
