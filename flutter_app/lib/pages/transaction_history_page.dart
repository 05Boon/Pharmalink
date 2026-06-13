import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {'id': 'TXN-00123', 'drug': 'Amoxicillin 500mg', 'pharmacy': 'City Pharmacy', 'date': '2026-06-01', 'status': 'Completed'},
      {'id': 'TXN-00122', 'drug': 'Metformin 1g', 'pharmacy': 'HealthPlus', 'date': '2026-05-30', 'status': 'Completed'},
      {'id': 'TXN-00121', 'drug': 'Ibuprofen 400mg', 'pharmacy': 'MediCare', 'date': '2026-05-28', 'status': 'Cancelled'},
    ];

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'History', path: '/history', active: true),
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
                      'Transaction history',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...transactions.map((txn) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFEA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    txn['id']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A18),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: txn['status'] == 'Completed'
                                          ? const Color(0xFFE1F5EE)
                                          : const Color(0xFFFCEBEB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      txn['status']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: txn['status'] == 'Completed'
                                            ? const Color(0xFF085041)
                                            : const Color(0xFF791F1F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                txn['drug']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5F5E5A),
                                ),
                              ),
                              Text(
                                '${txn['pharmacy']} • ${txn['date']}',
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
