import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final recentRequests = [
      {
        'drug': 'Amoxicillin 500mg',
        'from': 'City Pharmacy',
        'time': '2 min ago',
        'status': 'Pending',
        'color': const Color(0xFFFAEEDA),
        'textColor': const Color(0xFF633806),
      },
      {
        'drug': 'Metformin 1g',
        'from': 'HealthPlus',
        'time': '1 hr ago',
        'status': 'Accepted',
        'color': const Color(0xFFE1F5EE),
        'textColor': const Color(0xFF085041),
      },
      {
        'drug': 'Ibuprofen 400mg',
        'from': 'MediCare',
        'time': '3 hr ago',
        'status': 'Declined',
        'color': const Color(0xFFFCEBEB),
        'textColor': const Color(0xFF791F1F),
      },
    ];

    final activeQueries = [
      {
        'drug': 'Ciprofloxacin 250mg',
        'meta': 'Searching nearby…',
        'status': 'Searching',
        'color': const Color(0xFFFAEEDA),
        'textColor': const Color(0xFF633806),
      },
      {
        'drug': 'Atenolol 50mg',
        'meta': 'Match found',
        'status': 'Matched',
        'color': const Color(0xFFE1F5EE),
        'textColor': const Color(0xFF085041),
      },
      {
        'drug': 'Paracetamol 500mg',
        'meta': 'No match found',
        'status': 'Unmatched',
        'color': const Color(0xFFFCEBEB),
        'textColor': const Color(0xFF791F1F),
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard', active: true),
            NavLink(label: 'Search', path: '/search'),
            NavLink(label: 'Requests', path: '/requests'),
            NavLink(label: 'History', path: '/history'),
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
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5F5E5A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Expanded(
                          child: _StatCard(value: '3', label: 'Active queries'),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child:
                              _StatCard(value: '12', label: 'Requests received'),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: _StatCard(value: '8', label: 'Completed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent requests',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...recentRequests.map((req) => _RequestItem(
                                    drug: req['drug'] as String,
                                    from: req['from'] as String,
                                    time: req['time'] as String,
                                    status: req['status'] as String,
                                    color: req['color'] as Color,
                                    textColor: req['textColor'] as Color,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My active queries',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...activeQueries.map((query) => _QueryItem(
                                    drug: query['drug'] as String,
                                    meta: query['meta'] as String,
                                    status: query['status'] as String,
                                    color: query['color'] as Color,
                                    textColor: query['textColor'] as Color,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 180,
                      child: AppButton(
                        text: '+ New drug query',
                        onPressed: () => context.go('/search'),
                        fullWidth: false,
                      ),
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

class _RequestItem extends StatelessWidget {
  final String drug;
  final String from;
  final String time;
  final String status;
  final Color color;
  final Color textColor;

  const _RequestItem({
    required this.drug,
    required this.from,
    required this.time,
    required this.status,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E6DF)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  '$from · $time',
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

class _QueryItem extends StatelessWidget {
  final String drug;
  final String meta;
  final String status;
  final Color color;
  final Color textColor;

  const _QueryItem({
    required this.drug,
    required this.meta,
    required this.status,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E6DF)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  meta,
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
