import 'package:flutter/material.dart';
import '../../../widgets/app_nav.dart';
import '../models/outbreak_analytic_model.dart';
import '../models/pharmacy_node_model.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<PharmacyNode> _pharmacies = [];
  List<OutbreakAnalytic> _outbreaks = [];
  int _selectedDays = 7;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        AdminService.fetchPharmacies(),
        AdminService.fetchOutbreaks(days: _selectedDays),
      ]);

      setState(() {
        _pharmacies = results[0] as List<PharmacyNode>;
        _outbreaks = results[1] as List<OutbreakAnalytic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePharmacyStatus(PharmacyNode node) async {
    final currentStatus = node.accountStatus;
    final nextStatus = currentStatus.toUpperCase() == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    
    // Optimistic UI update
    setState(() {
      final idx = _pharmacies.indexWhere((p) => p.pharmacyId == node.pharmacyId);
      if (idx != -1) {
        _pharmacies[idx] = PharmacyNode(
          pharmacyId: node.pharmacyId,
          businessName: node.businessName,
          licenseNumber: node.licenseNumber,
          email: node.email,
          phoneNumber: node.phoneNumber,
          latitude: node.latitude,
          longitude: node.longitude,
          accountStatus: nextStatus, // Toggle status locally
          createdAt: node.createdAt,
        );
      }
    });

    try {
      final updatedNode = await AdminService.updatePharmacyStatus(node.pharmacyId, nextStatus);
      
      // Update UI with exact node from server
      setState(() {
        final idx = _pharmacies.indexWhere((p) => p.pharmacyId == node.pharmacyId);
        if (idx != -1) {
          _pharmacies[idx] = updatedNode;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${node.businessName} account status set to $nextStatus'),
            backgroundColor: nextStatus == 'ACTIVE' ? const Color(0xFF0F6E56) : const Color(0xFFB91C1C),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        final idx = _pharmacies.indexWhere((p) => p.pharmacyId == node.pharmacyId);
        if (idx != -1) {
          _pharmacies[idx] = node;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Overview', path: '/admin', active: true),
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies'),
            NavLink(label: 'Transactions', path: '/admin/transactions'),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadDashboardData,
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDashboardHeader(),
                            const SizedBox(height: 16),
                            _buildMetricsRow(),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildOutbreaksPanel(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: _buildPharmaciesPanel(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Operations Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A18),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Monitor geo-routing nodes, audit network usage, and review geospatial health outbreaks.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF5F5E5A),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              'Timeframe: ',
              style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
            ),
            const SizedBox(width: 4),
            DropdownButton<int>(
              value: _selectedDays,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A18), fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: 3, child: Text('Last 3 Days')),
                DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                DropdownMenuItem(value: 14, child: Text('Last 14 Days')),
                DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDays = val;
                  });
                  _loadDashboardData();
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadDashboardData,
            )
          ],
        )
      ],
    );
  }

  Widget _buildMetricsRow() {
    final activePharmacies = _pharmacies.where((p) => p.accountStatus.toUpperCase() == 'ACTIVE').length;
    final suspendedPharmacies = _pharmacies.length - activePharmacies;
    final totalOutbreakRequests = _outbreaks.fold<int>(0, (sum, item) => sum + item.requestFrequency);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Registered Nodes',
            value: '${_pharmacies.length}',
            subtitle: '$activePharmacies Active | $suspendedPharmacies Suspended',
            color: const Color(0xFFE2F3EE),
            textColor: const Color(0xFF0F6E56),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Outbreak Clusters',
            value: '${_outbreaks.length}',
            subtitle: '$totalOutbreakRequests total requests logged',
            color: const Color(0xFFFFF6E5),
            textColor: const Color(0xFFC07000),
          ),
        ),
      ],
    );
  }

  Widget _buildOutbreaksPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x80B4B2A9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFC07000), size: 18),
              SizedBox(width: 6),
              Text(
                'Geospatial Outbreaks (Heatmap Centroids)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_outbreaks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No outbreak clusters detected in this timeframe.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _outbreaks.length,
              separatorBuilder: (context, idx) => const Divider(color: Color(0xFFE8E6DF)),
              itemBuilder: (context, idx) {
                final o = _outbreaks[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${o.requestFrequency}x',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC07000),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.requestedDrug,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A18),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Centroid: [${o.centroidLatitude.toStringAsFixed(4)}, ${o.centroidLongitude.toStringAsFixed(4)}]',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5F5E5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPharmaciesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x80B4B2A9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy_outlined, color: Color(0xFF0F6E56), size: 18),
              SizedBox(width: 6),
              Text(
                'Network Nodes & Status Control',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pharmacies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No pharmacy nodes registered.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text('Business Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('License No.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Contact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Account Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: _pharmacies.map((p) {
                  final isActive = p.accountStatus.toUpperCase() == 'ACTIVE';
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.businessName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('Loc: [${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}]', style: const TextStyle(fontSize: 9, color: Color(0xFF5F5E5A))),
                          ],
                        ),
                      ),
                      DataCell(Text(p.licenseNumber, style: const TextStyle(fontSize: 11))),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.email, style: const TextStyle(fontSize: 10)),
                            Text(p.phoneNumber, style: const TextStyle(fontSize: 10, color: Color(0xFF5F5E5A))),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFE2F3EE) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.accountStatus,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isActive ? const Color(0xFF0F6E56) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                             Switch(
                              value: isActive,
                              activeThumbColor: const Color(0xFF0F6E56),
                              inactiveThumbColor: const Color(0xFFB91C1C),
                              inactiveTrackColor: const Color(0xFFFEE2E2),
                              onChanged: (val) {
                                _togglePharmacyStatus(p);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color textColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textColor.withAlpha(204)),
          ),
        ],
      ),
    );
  }
}
