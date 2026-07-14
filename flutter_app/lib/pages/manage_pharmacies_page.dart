import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class ManagePharmaciesPage extends StatefulWidget {
  const ManagePharmaciesPage({super.key});

  @override
  State<ManagePharmaciesPage> createState() => _ManagePharmaciesPageState();
}

class _ManagePharmaciesPageState extends State<ManagePharmaciesPage> {
  late Future<List<Map<String, dynamic>>> _pharmaciesFuture;

  @override
  void initState() {
    super.initState();
    // Initial admin data load for pharmacy governance table.
    _pharmaciesFuture = NetworkDataService.getPharmacies();
  }

  Future<void> _reload() async {
    // Re-fetch table after mutating actions such as delete.
    setState(() {
      _pharmaciesFuture = NetworkDataService.getPharmacies();
    });
  }

  Future<void> _deletePharmacy(Map<String, dynamic> pharmacy) async {
    // Admin delete flow with confirmation + backend policy feedback.
    final pharmacyId = '${pharmacy['pharmacy_id'] ?? ''}'.trim();
    final businessName =
        '${pharmacy['business_name'] ?? pharmacy['name'] ?? 'this pharmacy'}';
    if (pharmacyId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pharmacy ID is missing.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Pharmacy'),
          content: Text(
              'Delete $businessName from the network? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA32D2D)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await NetworkDataService.deletePharmacy(pharmacyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$businessName deleted successfully.')),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
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
            NavLink(label: 'Transactions', path: '/admin/transactions'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Core admin flow: list all pharmacy nodes and current account status.
              future: _pharmaciesFuture,
              builder: (context, snapshot) {
                final pharmacies =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                final hasError = snapshot.hasError;
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
                          'Manage pharmacies',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (hasError)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Unable to load pharmacies right now.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF791F1F),
                              ),
                            ),
                          ),
                        if (!hasError &&
                            snapshot.connectionState !=
                                ConnectionState.waiting &&
                            pharmacies.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No pharmacies found.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                          ),
                        if (snapshot.connectionState != ConnectionState.waiting)
                          ...pharmacies.map((pharmacy) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFEA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${pharmacy['business_name'] ?? pharmacy['name'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A18),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${pharmacy['email'] ?? '-'} • ${pharmacy['phone_number'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF5F5E5A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        // Backend returns `account_status`; fall back to
                                        // legacy `status` for compatibility.
                                        final accountStatus =
                                            '${pharmacy['account_status'] ?? pharmacy['status'] ?? '-'}';
                                        final isActive =
                                            accountStatus.toLowerCase() ==
                                                'active';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFFE1F5EE)
                                                : const Color(0xFFFAEEDA),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            accountStatus,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isActive
                                                  ? const Color(0xFF085041)
                                                  : const Color(0xFF633806),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Builder(
                                      builder: (context) {
                                        final accountStatus =
                                            '${pharmacy['account_status'] ?? pharmacy['status'] ?? '-'}';
                                        final isActive =
                                            accountStatus.toLowerCase() == 'active';
                                        return IconButton(
                                          tooltip: isActive
                                              ? 'Suspend this pharmacy before deleting'
                                              : 'Delete pharmacy',
                                          onPressed: isActive
                                              ? null
                                              : () => _deletePharmacy(pharmacy),
                                          icon: const Icon(Icons.delete_outline),
                                          color: const Color(0xFFA32D2D),
                                        );
                                      },
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
