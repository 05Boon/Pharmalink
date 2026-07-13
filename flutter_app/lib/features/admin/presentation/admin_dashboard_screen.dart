import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../widgets/app_nav.dart';
import '../models/outbreak_analytic_model.dart';
import '../models/pharmacy_node_model.dart';
import '../services/admin_service.dart';
import '../../../services/network_data_service.dart';
import '../../../models/outbreak_alert.dart';
import 'widgets/outbreak_map.dart';
import 'widgets/outbreak_list.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Controls map panning when selecting outbreak clusters from the list.
  final MapController _mapController = MapController();

  // Primary dashboard datasets loaded from admin endpoints.
  List<PharmacyNode> _pharmacies = [];
  List<OutbreakAnalytic> _outbreaks = [];
  List<OutbreakAlert> _alerts = [];
  Map<String, dynamic>? _report;

  // Shared timeframe for outbreaks and generated reports.
  int _selectedDays = 7;

  // Global and report-specific loading/error state.
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  String? _errorMessage;
  String? _reportErrorMessage;

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
      // Load dashboard sources concurrently to keep the admin page responsive.
      final results = await Future.wait([
        AdminService.fetchPharmacies(),
        AdminService.fetchOutbreaks(days: _selectedDays),
        AdminService.generateReport(days: _selectedDays),
        NetworkDataService.getOutbreakAlerts(),
      ]);

      setState(() {
        _pharmacies = results[0] as List<PharmacyNode>;
        _outbreaks = results[1] as List<OutbreakAnalytic>;
        _report = results[2] as Map<String, dynamic>;
        
        final rawAlerts = results[3] as List<Map<String, dynamic>>;
        _alerts = rawAlerts.map((e) => OutbreakAlert.fromJson(e)).toList();
        
        _reportErrorMessage = null;
      } else {
        _reportErrorMessage =
            'Report data unavailable right now. You can still view pharmacies and outbreaks.';
      }

      _errorMessage = (pharmacies.isEmpty &&
              outbreaks.isEmpty &&
              report == null &&
              sectionErrors.isNotEmpty)
          ? 'Failed to load dashboard data: ${sectionErrors.join(' | ')}'
          : null;

      _isLoading = false;
    });
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
      _reportErrorMessage = null;
    });

    try {
      // Refresh report payload, then immediately export it for download.
      final generated = await AdminService.generateReport(days: _selectedDays);
      if (!mounted) return;
      setState(() {
        _report = generated;
      });

      try {
        await AdminService.downloadReportCsv(
          days: _selectedDays,
          reportData: generated,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated and download started.'),
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
      } catch (downloadError) {
        if (!mounted) return;
        setState(() {
          _reportErrorMessage =
              'Report generated, but download failed: ${downloadError.toString()}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reportErrorMessage = 'Failed to generate report: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
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
                            _buildReportsPanel(),
                            const SizedBox(height: 20),
                            // Keep the geospatial map full-width for better readability.
                            _buildOutbreaksPanel(),
                            const SizedBox(height: 16),
                            _buildPharmaciesPanel(),
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
                  // Timeframe changes rehydrate all dashboard panels.
                  _loadDashboardData();
                }
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : _generateReport,
              icon: const Icon(Icons.auto_graph, size: 16),
              label: Text(
                _isGeneratingReport ? 'Generating...' : 'Generate & Download',
                style: const TextStyle(fontSize: 11),
              ),
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
    // Derived summary counters shown as top-level operational KPIs.
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: OutbreakMap(
                  outbreaks: _outbreaks,
                  mapController: _mapController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x80B4B2A9)),
                  ),
                  child: OutbreakList(
                    alerts: _alerts,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPanel() {
    // Normalize dynamic payload into strongly typed maps used by report widgets.
    final cards = (_report?['cards'] as List?)
        ?.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    final topDrugs = (_report?['top_requested_drugs'] as List?)
        ?.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    final topDrugsByArea = (_report?['top_requested_drugs_by_area'] as List?)
      ?.whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
        .toList() ??
      const <Map<String, dynamic>>[];

    return Container(
      width: double.infinity,
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
              Icon(Icons.assessment_outlined, color: Color(0xFF0F6E56), size: 18),
              SizedBox(width: 6),
              Text(
                'Generated Reports',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Generated at: ${_formatGeneratedAt(_report?['generated_at'])}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF5F5E5A)),
          ),
          if (_reportErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _reportErrorMessage!,
              style: const TextStyle(fontSize: 10, color: Color(0xFFB91C1C)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards
                .map(
                  (card) => _AdminReportCard(
                    title: '${card['title'] ?? '-'}',
                    description: '${card['description'] ?? '-'}',
                    icon: _reportIcon('${card['icon'] ?? ''}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Top Requested Drugs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 6),
          if (topDrugs.isEmpty)
            const Text(
              'No drug requests found for this timeframe.',
              style: TextStyle(fontSize: 10, color: Color(0xFF5F5E5A)),
            ),
          ...topDrugs.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item['drug_name'] ?? '-'}: ${item['request_count'] ?? 0} request(s)',
                style: const TextStyle(fontSize: 10, color: Color(0xFF1A1A18)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Most Requested Drug by Area',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const SizedBox(height: 6),
          if (topDrugsByArea.isEmpty)
            const Text(
              'No area-level demand pattern found for this timeframe.',
              style: TextStyle(fontSize: 10, color: Color(0xFF5F5E5A)),
            ),
          ...topDrugsByArea.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item['area_label'] ?? '-'}: ${item['top_drug'] ?? '-'} '
                '(${item['request_count'] ?? 0}/${item['total_requests_in_area'] ?? 0} requests)',
                style: const TextStyle(fontSize: 10, color: Color(0xFF1A1A18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGeneratedAt(dynamic value) {
    // Keep timestamp display compact for small dashboard panels.
    final raw = '${value ?? ''}';
    if (raw.length >= 16) {
      return raw.replaceFirst('T', ' ').substring(0, 16);
    }
    return raw.isEmpty ? '-' : raw;
  }

  IconData _reportIcon(String iconName) {
    // Maps backend icon names to Material icons.
    switch (iconName) {
      case 'bar_chart':
        return Icons.bar_chart;
      case 'assessment':
        return Icons.assessment;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.description;
    }
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

class _AdminReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _AdminReportCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFEA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                Text(
                  description,
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
  }
}
