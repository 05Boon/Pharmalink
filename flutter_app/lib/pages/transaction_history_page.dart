import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'fulfilled':
      case 'accepted':
        return const Color(0xFF085041);
      case 'pending':
        return const Color(0xFF633806);
      case 'expired':
      case 'canceled':
      case 'rejected':
        return const Color(0xFF791F1F);
      default:
        return const Color(0xFF5F5E5A);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'fulfilled':
      case 'accepted':
        return const Color(0xFFE6F3EE);
      case 'pending':
        return const Color(0xFFFFF0D4);
      case 'expired':
      case 'canceled':
      case 'rejected':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFE8E6DF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'History', path: '/history', active: true),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getTransactionHistory(),
              builder: (context, snapshot) {
                final transactions =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                        minHeight: 400,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFB4B2A9)),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transaction History',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A18),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Center(child: CircularProgressIndicator()),
                            if (snapshot.connectionState !=
                                    ConnectionState.waiting &&
                                transactions.isEmpty)
                              Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const Text(
                                  'No transaction history available.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF5F5E5A),
                                  ),
                                ),
                              ),
                            if (snapshot.connectionState !=
                                    ConnectionState.waiting &&
                                transactions.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: transactions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                  height: 16,
                                  thickness: 1,
                                  color: Color(0xFFE8E6DF),
                                ),
                                itemBuilder: (context, index) {
                                  final txn = transactions[index];
                                  final status = '${txn['status'] ?? '-'}';
                                  
                                  String dateStr = '-';
                                  final rawDate = txn['date'] ?? txn['created_at'];
                                  if (rawDate != null) {
                                    try {
                                      final dt = DateTime.parse(rawDate.toString());
                                      dateStr = DateFormat('MMM d, yyyy - h:mm a').format(dt);
                                    } catch (_) {
                                      dateStr = rawDate.toString();
                                    }
                                  }

                                  final drugName = txn['drug'] ?? txn['drug_name'] ?? 'Unknown Drug';
                                  final quantity = txn['quantity'] ?? txn['required_quantity'] ?? '-';
                                  final counterparty = txn['pharmacy'] ?? txn['counterparty'] ?? '-';

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Drug: $drugName - Qty: $quantity',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A18),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Partner: $counterparty',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF5F5E5A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF8B8A84),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusBgColor(status),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
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
