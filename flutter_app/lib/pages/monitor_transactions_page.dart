import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class MonitorTransactionsPage extends StatelessWidget {
  const MonitorTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies'),
            NavLink(
                label: 'Transactions',
                path: '/admin/transactions',
                active: true),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getMonitorTransactions(),
              builder: (context, snapshot) {
                final transactions =
                    snapshot.data ?? const <Map<String, dynamic>>[];
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
                          'Monitor transactions',
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
                          ...transactions.map((txn) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFEA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${txn['id'] ?? txn['transaction_id'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A18),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${txn['from'] ?? '-'} → ${txn['to'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF5F5E5A),
                                            ),
                                          ),
                                          Text(
                                            '${txn['drug'] ?? txn['drug_name'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF5F5E5A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            '${txn['status']}'.toLowerCase() ==
                                                    'completed'
                                                ? const Color(0xFFE1F5EE)
                                                : const Color(0xFFFAEEDA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${txn['status'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: '${txn['status']}'
                                                      .toLowerCase() ==
                                                  'completed'
                                              ? const Color(0xFF085041)
                                              : const Color(0xFF633806),
                                        ),
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
