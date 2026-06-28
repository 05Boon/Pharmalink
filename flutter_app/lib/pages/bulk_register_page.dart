import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../services/auth_service.dart';

/// Developer-only seed tool: registers 6 fake pharmacies spread across
/// Nairobi neighborhoods so multi-pharmacy features (PostGIS radius
/// search, stock-request alerts, WebSocket broadcast) can be tested
/// without manually filling the real registration form 6 times.
///
/// Not linked from any normal nav — reach it directly at /debug/bulk-register.
class BulkRegisterPage extends StatefulWidget {
  const BulkRegisterPage({super.key});

  @override
  State<BulkRegisterPage> createState() => _BulkRegisterPageState();
}

enum _SeedStatus { pending, running, success, failed }

class _SeedPharmacy {
  final String name;
  final String email;
  final String password;
  final String licenseNumber;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String neighborhood;

  _SeedStatus status;
  String? errorMessage;

  _SeedPharmacy({
    required this.name,
    required this.email,
    required this.password,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.neighborhood,
  }) : status = _SeedStatus.pending, errorMessage = null;
}

class _BulkRegisterPageState extends State<BulkRegisterPage> {
  bool _isRunning = false;
  bool _hasRun = false;

  // Hardcoded fake pharmacies spread across distinct Nairobi
  // neighborhoods so a search radius from any one of them returns a
  // genuinely different subset of the others — useful for testing
  // PostGIS ST_DWithin queries meaningfully rather than against
  // pharmacies that are all clustered in one spot.
  final List<_SeedPharmacy> _pharmacies = [
    _SeedPharmacy(
      name: 'CBD Test Pharmacy',
      email: 'cbd.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10001',
      phoneNumber: '0700100001',
      latitude: -1.2841,
      longitude: 36.8233,
      neighborhood: 'CBD',
    ),
    _SeedPharmacy(
      name: 'Westlands Test Pharmacy',
      email: 'westlands.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10002',
      phoneNumber: '0700100002',
      latitude: -1.2675,
      longitude: 36.8108,
      neighborhood: 'Westlands',
    ),
    _SeedPharmacy(
      name: 'Kilimani Test Pharmacy',
      email: 'kilimani.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10003',
      phoneNumber: '0700100003',
      latitude: -1.2906,
      longitude: 36.7820,
      neighborhood: 'Kilimani',
    ),
    _SeedPharmacy(
      name: 'Eastleigh Test Pharmacy',
      email: 'eastleigh.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10004',
      phoneNumber: '0700100004',
      latitude: -1.2784,
      longitude: 36.8470,
      neighborhood: 'Eastleigh',
    ),
    _SeedPharmacy(
      name: 'Karen Test Pharmacy',
      email: 'karen.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10005',
      phoneNumber: '0700100005',
      latitude: -1.3192,
      longitude: 36.7076,
      neighborhood: 'Karen',
    ),
    _SeedPharmacy(
      name: 'South B Test Pharmacy',
      email: 'southb.pharmacy@pharmalinktest.dev',
      password: 'testpass123',
      licenseNumber: 'PPB-10006',
      phoneNumber: '0700100006',
      latitude: -1.3107,
      longitude: 36.8345,
      neighborhood: 'South B',
    ),
  ];

  Future<void> _runBulkRegistration() async {
    setState(() {
      _isRunning = true;
      _hasRun = true;
      for (final p in _pharmacies) {
        p.status = _SeedStatus.pending;
        p.errorMessage = null;
      }
    });

    // Sequential, not parallel — firing 6 signUps at once against
    // Supabase Auth risks tripping rate limits. A short delay between
    // each call gives Supabase room to breathe.
    for (final pharmacy in _pharmacies) {
      setState(() => pharmacy.status = _SeedStatus.running);

      try {
        final result = await AuthService.register(
          name: pharmacy.name,
          email: pharmacy.email,
          password: pharmacy.password,
          licenseNumber: pharmacy.licenseNumber,
          phoneNumber: pharmacy.phoneNumber,
          latitude: pharmacy.latitude,
          longitude: pharmacy.longitude,
        );

        if (!mounted) return;

        if (result['ok'] == true) {
          setState(() => pharmacy.status = _SeedStatus.success);
        } else {
          setState(() {
            pharmacy.status = _SeedStatus.failed;
            pharmacy.errorMessage =
                result['error']?['message']?.toString() ?? 'Unknown error';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          pharmacy.status = _SeedStatus.failed;
          pharmacy.errorMessage = e.toString();
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    setState(() => _isRunning = false);
  }

  int get _successCount =>
      _pharmacies.where((p) => p.status == _SeedStatus.success).length;
  int get _failedCount =>
      _pharmacies.where((p) => p.status == _SeedStatus.failed).length;
  bool get _isComplete =>
      _hasRun && !_isRunning && (_successCount + _failedCount) == _pharmacies.length;

  Color _statusColor(_SeedStatus status) {
    switch (status) {
      case _SeedStatus.success:
        return const Color(0xFF1D9E75);
      case _SeedStatus.failed:
        return const Color(0xFFA32D2D);
      case _SeedStatus.running:
        return const Color(0xFFB8860B);
      case _SeedStatus.pending:
        return const Color(0xFF9A988F);
    }
  }

  IconData _statusIcon(_SeedStatus status) {
    switch (status) {
      case _SeedStatus.success:
        return Icons.check_circle;
      case _SeedStatus.failed:
        return Icons.error;
      case _SeedStatus.running:
        return Icons.sync;
      case _SeedStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  String _statusLabel(_SeedStatus status) {
    switch (status) {
      case _SeedStatus.success:
        return 'Registered';
      case _SeedStatus.failed:
        return 'Failed';
      case _SeedStatus.running:
        return 'Registering...';
      case _SeedStatus.pending:
        return 'Waiting';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Login', path: '/'),
          ]),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
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
                      const Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 16,
                            color: Color(0xFF5F5E5A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Bulk register test pharmacies',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Developer tool — registers 6 fake pharmacies across '
                        'Nairobi to seed data for testing geospatial search '
                        'and stock-request alerts.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pharmacy list with live status
                      ...List.generate(_pharmacies.length, (i) {
                        final p = _pharmacies[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F6F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE3E1D8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _statusIcon(p.status),
                                size: 14,
                                color: _statusColor(p.status),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p.name} (${p.neighborhood})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    Text(
                                      p.email,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF9A988F),
                                      ),
                                    ),
                                    if (p.status == _SeedStatus.failed &&
                                        p.errorMessage != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          p.errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFFA32D2D),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _statusLabel(p.status),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: _statusColor(p.status),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      if (_isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFAF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF1D9E75),
                            ),
                          ),
                          child: Text(
                            '$_successCount succeeded, $_failedCount failed',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F6E56),
                            ),
                          ),
                        ),

                      AppButton(
                        text: _isRunning
                            ? 'Registering pharmacies...'
                            : _hasRun
                                ? 'Run again'
                                : 'Run bulk registration',
                        onPressed: _isRunning ? null : _runBulkRegistration,
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/'),
                          child: const Text(
                            'Back to login',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0F6E56),
                            ),
                          ),
                        ),
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