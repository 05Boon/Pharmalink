import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';

class ManagePharmaciesPage extends StatelessWidget {
  const ManagePharmaciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pharmacies = [
      {'name': 'City Pharmacy', 'location': 'Downtown', 'status': 'Active'},
      {'name': 'HealthPlus', 'location': 'Uptown', 'status': 'Active'},
      {'name': 'MediCare', 'location': 'Westside', 'status': 'Active'},
      {'name': 'Green Leaf', 'location': 'Eastside', 'status': 'Pending'},
    ];

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin'),
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies', active: true),
            NavLink(label: 'Transactions', path: '/admin/transactions'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pharmacy['name']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pharmacy['location']!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pharmacy['status'] == 'Active'
                                      ? const Color(0xFFE1F5EE)
                                      : const Color(0xFFFAEEDA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  pharmacy['status']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pharmacy['status'] == 'Active'
                                        ? const Color(0xFF085041)
                                        : const Color(0xFF633806),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
