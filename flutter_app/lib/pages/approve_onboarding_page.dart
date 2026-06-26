import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class ApproveOnboardingPage extends StatefulWidget {
  final String pharmacyId;

  const ApproveOnboardingPage({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<ApproveOnboardingPage> createState() => _ApproveOnboardingPageState();
}

class _ApproveOnboardingPageState extends State<ApproveOnboardingPage> {
  bool _submitting = false;

  Future<void> _submitDecision(bool approved) async {
    setState(() {
      _submitting = true;
    });

    try {
      await NetworkDataService.reviewOnboardingPharmacy(
        pharmacyId: widget.pharmacyId,
        approved: approved,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved
              ? 'Pharmacy approved successfully.'
              : 'Pharmacy rejected successfully.'),
        ),
      );
      context.go('/admin/pharmacies');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit decision. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(
                label: 'Pharmacies', path: '/admin/pharmacies', active: true),
          ]),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: NetworkDataService.getOnboardingDetail(widget.pharmacyId),
              builder: (context, snapshot) {
                final detail = snapshot.data ?? const <String, dynamic>{};
                return Padding(
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(child: CircularProgressIndicator()),
                          if (snapshot.connectionState !=
                              ConnectionState.waiting)
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
                                    '${detail['name'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A18),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${detail['location'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF5F5E5A),
                                    ),
                                  ),
                                  Text(
                                    'Owner: ${detail['owner'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF5F5E5A),
                                    ),
                                  ),
                                  Text(
                                    'Email: ${detail['email'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF5F5E5A),
                                    ),
                                  ),
                                  Text(
                                    'Applied: ${detail['applied'] ?? '-'}',
                                    style: const TextStyle(
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
                                  text: _submitting ? 'Saving...' : 'Approve',
                                  onPressed: _submitting
                                      ? null
                                      : () => _submitDecision(true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => _submitDecision(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF791F1F),
                                    side: const BorderSide(
                                        color: Color(0xFF791F1F)),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
