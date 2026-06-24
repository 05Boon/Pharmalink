import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class ViewResponsePage extends StatelessWidget {
  const ViewResponsePage({super.key});

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
            child: FutureBuilder<Map<String, dynamic>>(
              future: NetworkDataService.getSentRequestDetails(),
              builder: (context, snapshot) {
                final details = snapshot.data ?? const <String, dynamic>{};
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB4B2A9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request sent',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EFEA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To: ${details['to'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A18),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Drug: ${details['drug'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF5F5E5A),
                                  ),
                                ),
                                Text(
                                  'Quantity: ${details['quantity'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF5F5E5A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${details['status'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF633806),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
