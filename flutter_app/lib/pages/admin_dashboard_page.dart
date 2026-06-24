import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../services/mock_data_store.dart';
import '../services/network_data_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin', active: true),
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies'),
            NavLink(label: 'Transactions', path: '/admin/transactions'),
            NavLink(label: 'Reports', path: '/admin/reports'),
            NavLink(label: 'Logs', path: '/admin/logs'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: NetworkDataService.getAdminDashboardData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? const <String, dynamic>{};
                final stats = (data['stats'] as Map<String, dynamic>?) ??
                    Map<String, dynamic>.from(MockDataStore.adminStats);
                final recentTransactions =
                    (data['recent_transactions'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        MockDataStore.adminRecentTransactions
                            .map((item) => Map<String, dynamic>.from(item))
                            .toList();
                final pendingApprovals = (data['pending_approvals'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    MockDataStore.adminPendingApprovals
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList();
                final systemHealth = (data['system_health'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    MockDataStore.adminSystemHealth
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList();

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
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                value: '${stats['pharmacies'] ?? '0'}',
                                label: 'Pharmacies',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['queries_today'] ?? '0'}',
                                label: 'Queries today',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['completed'] ?? '0'}',
                                label: 'Completed',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['pending_approvals'] ?? '0'}',
                                label: 'Pending approvals',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (snapshot.connectionState != ConnectionState.waiting)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Recent transactions',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...recentTransactions.map((txn) {
                                      final status = '${txn['status'] ?? '-'}';
                                      final style =
                                          MockDataStore.statusStyle(status);
                                      return _TransactionItem(
                                        id: '${txn['id'] ?? txn['transaction_id'] ?? '-'}',
                                        from: '${txn['from'] ?? '-'}',
                                        status: status,
                                        color: style.color,
                                        textColor: style.textColor,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending approvals',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...pendingApprovals.map((approval) {
                                      final id = '${approval['id'] ?? '1'}';
                                      return GestureDetector(
                                        onTap: () => context.go(
                                            '/admin/pharmacies/approve/$id'),
                                        child: _ApprovalItem(
                                          name: '${approval['name'] ?? '-'}',
                                          time: '${approval['time'] ?? '-'}',
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'System health',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...systemHealth.map((item) {
                                      final state =
                                          '${item['state'] ?? 'neutral'}';
                                      final style =
                                          MockDataStore.statusStyle(state);
                                      return _HealthItem(
                                        label: '${item['label'] ?? '-'}',
                                        value: '${item['value'] ?? '-'}',
                                        valueColor: style.textColor,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFEA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5F5E5A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String id;
  final String from;
  final String status;
  final Color color;
  final Color textColor;

  const _TransactionItem({
    required this.id,
    required this.from,
    required this.status,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6DF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  from,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  final String name;
  final String time;

  const _ApprovalItem({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6DF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Review',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF633806),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _HealthItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6DF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5F5E5A),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
