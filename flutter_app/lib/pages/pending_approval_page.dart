import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/auth_service.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppNav(links: []),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB4B2A9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 48, color: Color(0xFF5F5E5A)),
                      const SizedBox(height: 16),
                      const Text(
                        'Account Pending Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your account application is currently under review by the administrator. Please check back later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Log Out',
                        onPressed: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
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
