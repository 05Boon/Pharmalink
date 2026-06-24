import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Requests', path: '/requests', active: true),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.getIncomingRequests(),
              builder: (context, snapshot) {
                final requests =
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
                          'Incoming requests',
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
                          ...requests.map((req) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFEA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From: ${req['from'] ?? req['source'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req['drug'] ?? req['drug_name'] ?? '-'} • ${req['qty'] ?? req['quantity'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req['time'] ?? req['created_at'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => context
                                                .go('/requests/accepted'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF1D9E75),
                                              foregroundColor:
                                                  const Color(0xFF04342C),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              textStyle:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            child: const Text('Accept'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {},
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFF791F1F),
                                              side: const BorderSide(
                                                  color: Color(0xFF791F1F)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              textStyle:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            child: const Text('Decline'),
                                          ),
                                        ),
                                      ],
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
