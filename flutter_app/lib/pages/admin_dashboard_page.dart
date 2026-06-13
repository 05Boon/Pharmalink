import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';

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
                  children: [
                    const Row(
                      children: [
                        Expanded(child: _StatCard(value: '47', label: 'Pharmacies')),
                        SizedBox(width: 6),
                        Expanded(child: _StatCard(value: '132', label: 'Queries today')),
                        SizedBox(width: 6),
                        Expanded(child: _StatCard(value: '89', label: 'Completed')),
                        SizedBox(width: 6),
                        Expanded(child: _StatCard(value: '5', label: 'Pending approvals')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent transactions',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              SizedBox(height: 6),
                              _TransactionItem(
                                id: 'TXN-00421',
                                from: 'City → HealthPlus',
                                status: 'Done',
                                color: Color(0xFFE1F5EE),
                                textColor: Color(0xFF085041),
                              ),
                              _TransactionItem(
                                id: 'TXN-00420',
                                from: 'MediCare → PharmCity',
                                status: 'Pending',
                                color: Color(0xFFFAEEDA),
                                textColor: Color(0xFF633806),
                              ),
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
                              GestureDetector(
                                onTap: () => context.go('/admin/pharmacies/approve/1'),
                                child: const _ApprovalItem(
                                  name: 'Green Leaf',
                                  time: 'Applied 2 days ago',
                                ),
                              ),
                              const _ApprovalItem(
                                name: 'SunCare Chemist',
                                time: 'Applied today',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System health',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              SizedBox(height: 6),
                              _HealthItem(
                                label: 'Uptime',
                                value: '99.8%',
                                valueColor: Color(0xFF085041),
                              ),
                              _HealthItem(
                                label: 'Avg response',
                                value: '4.2 min',
                                valueColor: Color(0xFF1A1A18),
                              ),
                              _HealthItem(
                                label: 'Match rate',
                                value: '89%',
                                valueColor: Color(0xFF085041),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
