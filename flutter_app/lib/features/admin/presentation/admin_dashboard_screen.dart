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
import 'widgets/regional_demand_chart.dart';class AdminDashboardScreen extends StatefulWidget {
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
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated, but download failed: ${downloadError.toString()}'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: ${e.toString()}'),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
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
                              _buildRegionalDemandPanel(),
                              const SizedBox(height: 20),
                              // Keep the geospatial map full-width for better readability.
                              _buildOutbreaksPanel(),
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
    final activePharmacies = _pharmacies.where((p) => p.accountStatus.toUpperCase() == 'ACTIVE').length;
    final totalOutbreakRequests = _outbreaks.fold<int>(0, (sum, item) => sum + item.requestFrequency);
    
    final fulfillmentRate = _report?['fulfillment_rate'] as double? ?? 0.0;
    final avgResTime = _report?['average_resolution_time_mins'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Active Nodes',
            value: '$activePharmacies',
            subtitle: '${_pharmacies.length} Total Registered',
            color: const Color(0xFFE2F3EE),
            textColor: const Color(0xFF0F6E56),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Outbreak Clusters',
            value: '${_outbreaks.length}',
            subtitle: '$totalOutbreakRequests total requests',
            color: const Color(0xFFFFF6E5),
            textColor: const Color(0xFFC07000),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Fulfillment Rate',
            value: '${fulfillmentRate.toStringAsFixed(1)}%',
            subtitle: 'Overall system fulfillment',
            color: const Color(0xFFEAF2FF),
            textColor: const Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Avg Resolution',
            value: '$avgResTime m',
            subtitle: 'Average time to fulfill',
            color: const Color(0xFFF3E8FF),
            textColor: const Color(0xFF6B21A8),
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

  Widget _buildRegionalDemandPanel() {
    final regionalData = (_report?['top_requested_drugs_by_area'] as List?)
        ?.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList() ?? [];
    return RegionalDemandChart(demandData: regionalData);
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
