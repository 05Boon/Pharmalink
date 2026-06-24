import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class AcceptSharePage extends StatelessWidget {
  const AcceptSharePage({super.key});

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
            child: FutureBuilder<Map<String, dynamic>>(
              future: NetworkDataService.getAcceptedRequestDetails(),
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
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE1F5EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Color(0xFF1D9E75),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Request accepted',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have accepted the request from ${details['from'] ?? '-'} for ${details['drug'] ?? '-'}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5F5E5A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Back to requests',
                            onPressed: () => context.go('/requests'),
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
