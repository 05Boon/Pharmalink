import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard', active: true),
            NavLink(label: 'Search', path: '/search'),
            NavLink(label: 'Responder', path: '/search/response'),
            NavLink(label: 'Requests', path: '/requests'),
            NavLink(label: 'History', path: '/history'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: NetworkDataService.getOwnerDashboardData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? const <String, dynamic>{};
                final stats = (data['stats'] as Map<String, dynamic>?) ??
                    const <String, dynamic>{};
                final recentRequests = (data['recent_requests'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    const <Map<String, dynamic>>[];
                final activeQueries = (data['active_queries'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    const <Map<String, dynamic>>[];

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
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5F5E5A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                value: '${stats['active_queries'] ?? '0'}',
                                label: 'Active queries',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['requests_received'] ?? '0'}',
                                label: 'Requests received',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['completed'] ?? '0'}',
                                label: 'Completed',
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
                                      'Recent requests',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...recentRequests.map((req) {
                                      final status =
                                          '${req['status'] ?? 'Pending'}';
                                      final style = _statusStyle(status);
                                      return _RequestItem(
                                        drug:
                                            '${req['drug'] ?? req['drug_name'] ?? '-'}',
                                        from:
                                            '${req['from'] ?? req['source'] ?? '-'}',
                                        time:
                                            '${req['time'] ?? req['created_at'] ?? '-'}',
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
                                      'My active queries',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...activeQueries.map((query) {
                                      final status =
                                          '${query['status'] ?? '-'}';
                                      final style = _statusStyle(status);
                                      return _QueryItem(
                                        drug:
                                            '${query['drug'] ?? query['drug_name'] ?? '-'}',
                                        meta: '${query['meta'] ?? '-'}',
                                        status: status,
                                        color: style.color,
                                        textColor: style.textColor,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 180,
                              child: AppButton(
                                text: '+ New drug query',
                                onPressed: () => context.go('/search'),
                                fullWidth: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: OutlinedButton(
                                onPressed: () => context.go('/inventory'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1D9E75),
                                  side: const BorderSide(
                                      color: Color(0xFF1D9E75)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                ),
                                child: const Text('Manage Stock',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: OutlinedButton(
                                onPressed: () => context.go('/search/response'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF633806),
                                  side: const BorderSide(
                                      color: Color(0xFF633806)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                ),
                                child: const Text('Responder Page',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
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

({Color color, Color textColor}) _statusStyle(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
    case 'completed':
    case 'done':
    case 'active':
    case 'matched':
      return (
        color: const Color(0xFFE1F5EE),
        textColor: const Color(0xFF085041),
      );
    case 'pending':
    case 'searching':
    case 'review':
      return (
        color: const Color(0xFFFAEEDA),
        textColor: const Color(0xFF633806),
      );
    default:
      return (
        color: const Color(0xFFFCEBEB),
        textColor: const Color(0xFF791F1F),
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
