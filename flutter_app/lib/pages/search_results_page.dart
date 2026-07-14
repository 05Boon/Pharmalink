import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class SearchResultsPage extends StatelessWidget {
  final String? query;

  const SearchResultsPage({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    // This screen does not create requests. The broadcast is already sent from
    // DrugQueryPage via NetworkDataService.createStockRequestAndBroadcast().
    final effectiveQuery = (query == null || query!.trim().isEmpty)
        ? 'Amoxicillin 500mg'
        : query!.trim();

    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Search', path: '/search', active: true),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: NetworkDataService.searchDrugs(effectiveQuery),
              builder: (context, snapshot) {
                final results = snapshot.data ?? const <Map<String, dynamic>>[];

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
                          'Search results',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Found ${results.length} matches for $effectiveQuery',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5F5E5A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Requests have already been sent automatically to nearby pharmacies.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF085041),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (snapshot.connectionState != ConnectionState.waiting)
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
                                      '${result['pharmacy'] ?? result['name'] ?? 'Unknown pharmacy'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${result['distance'] ?? '-'} • ${result['stock'] ?? result['quantity'] ?? '-'} available',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${result['price'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1D9E75),
                                          ),
                                        ),
                                        Container(
                                          // Requests are already broadcast from
                                          // DrugQueryPage; this list is read-only
                                          // visibility of nearby matches.
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE1F5EE),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Request sent',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF085041),
                                            ),
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
