import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final results = [
      {'pharmacy': 'City Pharmacy', 'distance': '2.3 km', 'price': '\$45.00', 'stock': '120 units'},
      {'pharmacy': 'HealthPlus', 'distance': '4.1 km', 'price': '\$42.50', 'stock': '80 units'},
      {'pharmacy': 'MediCare', 'distance': '6.8 km', 'price': '\$48.00', 'stock': '50 units'},
    ];

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Search', path: '/search', active: true),
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
                      'Search results',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Found 3 matches for Amoxicillin 500mg',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5F5E5A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...results.map((result) => Container(
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
                                result['pharmacy']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${result['distance']} • ${result['stock']} available',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5F5E5A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    result['price']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D9E75),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => context.go('/search/response'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D9E75),
                                      foregroundColor: const Color(0xFF04342C),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      textStyle: const TextStyle(fontSize: 10),
                                    ),
                                    child: const Text('Request'),
                                  ),
                                ],
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
