import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class ViewResponsePage extends StatelessWidget {
  const ViewResponsePage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
      case 'accepted':
      case 'completed':
        return const Color(0xFF085041);
      case 'pending':
        return const Color(0xFF633806);
      default:
        return const Color(0xFF5F5E5A);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
      case 'accepted':
      case 'completed':
        return const Color(0xFFE6F3EE);
      case 'pending':
        return const Color(0xFFFFF0D4);
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
            NavLink(label: 'Search', path: '/search', active: true),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getSentRequestsDetails(),
              builder: (context, snapshot) {
                final sentRequests =
                    snapshot.data ?? const <Map<String, dynamic>>[];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 560, minHeight: 300),
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
                            'My request responses',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator()),
                          if (snapshot.hasError)
                            const Text(
                              'Could not load responses right now.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF791F1F),
                              ),
                            ),
                          if (!snapshot.hasError &&
                              snapshot.connectionState !=
                                  ConnectionState.waiting &&
                              sentRequests.isEmpty)
                            Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: const Text(
                                'No responses yet. Create a request and they will appear here.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF5F5E5A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (!snapshot.hasError &&
                              snapshot.connectionState !=
                                  ConnectionState.waiting)
                            ...sentRequests.map((details) {
                              final status =
                                  '${details['request_status'] ?? '-'}';
                              final acceptedBy =
                                  details['accepted_by_pharmacy'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFEA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Drug: ${details['requested_drug'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${details['required_quantity'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        String dateStr = '-';
                                        if (details['created_at'] != null) {
                                          try {
                                            final dt = DateTime.parse(details['created_at']);
                                            dateStr = DateFormat('MMM d, yyyy - h:mm a').format(dt);
                                          } catch (_) {
                                            dateStr = details['created_at'];
                                          }
                                        }
                                        return Text(
                                          'Sent: $dateStr',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF5F5E5A),
                                          ),
                                        );
                                      }
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusBgColor(status),
                                        borderRadius: BorderRadius.circular(4),
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
                                    if (acceptedBy is Map<String, dynamic>) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accepted by: ${acceptedBy['business_name'] ?? '-'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF085041),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Contact: ${acceptedBy['phone_number'] ?? '-'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5F5E5A),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 8),
                          AppButton(
                            text: 'Back to dashboard',
                            onPressed: () => context.go('/dashboard'),
                          ),
                        ],
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
