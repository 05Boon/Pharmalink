import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';
import 'widgets/frequent_drugs_chart.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardDataFuture = NetworkDataService.getOwnerDashboardData();
    });
  }

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
            NavLink(label: 'Profile', path: '/profile'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dashboardDataFuture,
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

                final frequentDrugs = (data['frequent_drugs'] as List?)
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
                                label: 'My Active Shortages',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['neighbor_alerts'] ?? '0'}',
                                label: 'Neighbor Alerts',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatCard(
                                value: '${stats['community_contribution'] ?? '0'}',
                                label: 'Community Contribution',
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
                                      'My active queries',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (activeQueries.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Text(
                                            'No active shortages right now.',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF5F5E5A),
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    else
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
                                          onTap: () => _showCancelQueryModal(query),
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
                                      'Incoming neighbor alerts',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (recentRequests.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Text(
                                            "No alerts from neighbors. You're all caught up!",
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF5F5E5A),
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    else
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
                                          onTap: () => _showAcceptAlertModal(req),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        FrequentDrugsChart(drugs: frequentDrugs),
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

  void _showAcceptAlertModal(Map<String, dynamic> req) {
    // Only allow unread/pending to be accepted
    final status = '${req['status'] ?? 'Pending'}'.toUpperCase();
    if (status == 'ACCEPTED' || status == 'DECLINED' || status == 'DONE') return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Incoming Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Pharmacy: ${req['from'] ?? req['source'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Drug: ${req['drug'] ?? req['drug_name'] ?? '-'}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6E56),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // For the purpose of the mock, we assume req['id'] or request_id exists.
                        // We will need to map this carefully if the backend doesn't return the ID.
                        // Assuming the API returns the alert id or request id.
                        try {
                          await NetworkDataService.respondToIncomingRequest(
                            requestId: req['id'] ?? req['request_id'] ?? '', 
                            accepted: true
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _refreshDashboard();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to accept: $e')),
                          );
                        }
                      },
                      child: const Text('Accept Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelQueryModal(Map<String, dynamic> query) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cancel Query',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text('Drug: ${query['drug'] ?? query['drug_name'] ?? '-'}'),
              const SizedBox(height: 8),
              Text('Status: ${query['status'] ?? '-'}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep Active'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          // Call your cancel query API here.
                          // e.g. await NetworkDataService.cancelRequest(...)
                          // We simulate it here if it doesn't exist.
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _refreshDashboard();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to cancel: $e')),
                          );
                        }
                      },
                      child: const Text('Cancel Query'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
  final VoidCallback? onTap;

  const _RequestItem({
    required this.drug,
    required this.from,
    required this.time,
    required this.status,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
  final VoidCallback? onTap;

  const _QueryItem({
    required this.drug,
    required this.meta,
    required this.status,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
      ),
    );
  }
}
