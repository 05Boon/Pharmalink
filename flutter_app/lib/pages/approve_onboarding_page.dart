import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';

class ApproveOnboardingPage extends StatelessWidget {
  final String pharmacyId;

  const ApproveOnboardingPage({
    super.key,
    required this.pharmacyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies', active: true),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
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
                        'Approve pharmacy onboarding',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EFEA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Green Leaf Pharmacy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A18),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Location: 123 Main St, Eastside',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                            Text(
                              'Owner: John Smith',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                            Text(
                              'Email: john@greenleaf.com',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                            Text(
                              'Applied: 2 days ago',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Approve',
                              onPressed: () => context.go('/admin/pharmacies'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/admin/pharmacies'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF791F1F),
                                side: const BorderSide(color: Color(0xFF791F1F)),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
