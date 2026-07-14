import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_nav.dart';
import '../features/admin/services/admin_service.dart';
import '../features/admin/models/pharmacy_node_model.dart';
import '../services/network_data_service.dart';

class ManagePharmaciesPage extends StatefulWidget {
  const ManagePharmaciesPage({super.key});

  @override
  State<ManagePharmaciesPage> createState() => _ManagePharmaciesPageState();
}

class _ManagePharmaciesPageState extends State<ManagePharmaciesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  
  List<PharmacyNode> _pharmacies = [];
  bool _isLoading = true;
  String? _errorMessage;
  PharmacyNode? _selectedPharmacy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPharmacies();
  }
  
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedPharmacy = null;
      });
    }
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await AdminService.fetchPharmacies();
      setState(() {
        _pharmacies = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(PharmacyNode node, String newStatus) async {
    try {
      final updatedNode = await AdminService.updatePharmacyStatus(node.pharmacyId, newStatus);
      setState(() {
        final idx = _pharmacies.indexWhere((p) => p.pharmacyId == node.pharmacyId);
        if (idx != -1) {
          _pharmacies[idx] = updatedNode;
        }
        if (_selectedPharmacy?.pharmacyId == node.pharmacyId) {
          _selectedPharmacy = updatedNode;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${node.businessName} account status set to $newStatus'),
          backgroundColor: newStatus == 'ACTIVE' ? const Color(0xFF0F6E56) : const Color(0xFFC07000),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  Future<void> _deletePharmacy(PharmacyNode node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Pharmacy'),
          content: Text('Delete ${node.businessName} from the network? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFA32D2D)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await NetworkDataService.deletePharmacy(node.pharmacyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${node.businessName} deleted successfully.'),
          backgroundColor: const Color(0xFF0F6E56),
        ),
      );
      setState(() {
        _pharmacies.removeWhere((p) => p.pharmacyId == node.pharmacyId);
        if (_selectedPharmacy?.pharmacyId == node.pharmacyId) {
          _selectedPharmacy = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  void _selectPharmacy(PharmacyNode node) {
    setState(() {
      _selectedPharmacy = node;
    });
    _mapController.move(LatLng(node.latitude, node.longitude), 15.0);
  }

  List<PharmacyNode> get _filteredPharmacies {
    final statusMap = {0: 'PENDING', 1: 'ACTIVE', 2: 'SUSPENDED'};
    final status = statusMap[_tabController.index];
    return _pharmacies.where((p) => p.accountStatus.toUpperCase() == status).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadPharmacies,
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          // Left Panel (List & Tabs)
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Color(0xFFB4B2A9))),
                                color: Color(0xFFF9F8F6),
                              ),
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: const Color(0xFF1A1A18),
                                    unselectedLabelColor: const Color(0xFF5F5E5A),
                                    indicatorColor: const Color(0xFF0F6E56),
                                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                                    tabs: [
                                      Tab(text: 'Pending (${_pharmacies.where((p) => p.accountStatus.toUpperCase() == 'PENDING').length})'),
                                      Tab(text: 'Active (${_pharmacies.where((p) => p.accountStatus.toUpperCase() == 'ACTIVE').length})'),
                                      Tab(text: 'Suspended (${_pharmacies.where((p) => p.accountStatus.toUpperCase() == 'SUSPENDED').length})'),
                                    ],
                                  ),
                                  Expanded(
                                    child: _filteredPharmacies.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No pharmacies found in this status.',
                                              style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: const EdgeInsets.all(12),
                                            itemCount: _filteredPharmacies.length,
                                            separatorBuilder: (context, index) => const Divider(color: Color(0x80B4B2A9), height: 1),
                                            itemBuilder: (context, index) {
                                              final node = _filteredPharmacies[index];
                                              final isSelected = _selectedPharmacy?.pharmacyId == node.pharmacyId;
                                              return ListTile(
                                                selected: isSelected,
                                                selectedTileColor: const Color(0xFFE2F3EE),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                title: Text(node.businessName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A18))),
                                                subtitle: Text('${node.generalLocation}\n${node.email}', style: const TextStyle(fontSize: 10, color: Color(0xFF5F5E5A))),
                                                isThreeLine: true,
                                                onTap: () => _selectPharmacy(node),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right Panel (Map & Details)
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: const MapOptions(
                                    initialCenter: LatLng(-1.2921, 36.8219), // Nairobi default
                                    initialZoom: 6.0,
                                    maxZoom: 18.0,
                                    minZoom: 2.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.pharmalink.app',
                                    ),
                                    MarkerLayer(
                                      markers: _filteredPharmacies.map((node) {
                                        final isSelected = _selectedPharmacy?.pharmacyId == node.pharmacyId;
                                        final isPending = node.accountStatus.toUpperCase() == 'PENDING';
                                        final isSuspended = node.accountStatus.toUpperCase() == 'SUSPENDED';
                                        
                                        Color markerColor = const Color(0xFF0F6E56); // Active
                                        if (isPending) markerColor = const Color(0xFFC07000);
                                        if (isSuspended) markerColor = const Color(0xFFA32D2D);

                                        if (isSelected) markerColor = const Color(0xFF1A1A18); // Highlighted

                                        return Marker(
                                          point: LatLng(node.latitude, node.longitude),
                                          width: isSelected ? 48 : 36,
                                          height: isSelected ? 48 : 36,
                                          child: GestureDetector(
                                            onTap: () => _selectPharmacy(node),
                                            child: Icon(
                                              Icons.location_on,
                                              color: markerColor,
                                              size: isSelected ? 48 : 36,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                if (_selectedPharmacy != null)
                                  Positioned(
                                    bottom: 24,
                                    left: 24,
                                    right: 24,
                                    child: _buildDetailCard(_selectedPharmacy!),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(PharmacyNode node) {
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x80B4B2A9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    node.businessName, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A18)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF5F5E5A)),
                  onPressed: () => setState(() => _selectedPharmacy = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF5F5E5A)),
                const SizedBox(width: 8),
                Text('License: ${node.licenseNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A18))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5F5E5A)),
                const SizedBox(width: 8),
                Text('Region: ${node.generalLocation}', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A18))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.contact_mail_outlined, size: 16, color: Color(0xFF5F5E5A)),
                const SizedBox(width: 8),
                Text('${node.email}  •  ${node.phoneNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A18))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (node.accountStatus.toUpperCase() == 'PENDING')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(node, 'ACTIVE'),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Approve'),
                  ),
                if (node.accountStatus.toUpperCase() == 'ACTIVE')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC07000),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(node, 'SUSPENDED'),
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Suspend'),
                  ),
                if (node.accountStatus.toUpperCase() == 'SUSPENDED')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(node, 'ACTIVE'),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Activate'),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Delete pharmacy',
                  onPressed: () => _deletePharmacy(node),
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFA32D2D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
