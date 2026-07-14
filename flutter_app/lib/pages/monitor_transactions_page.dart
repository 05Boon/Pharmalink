import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';

class MonitorTransactionsPage extends StatefulWidget {
  const MonitorTransactionsPage({super.key});

  @override
  State<MonitorTransactionsPage> createState() => _MonitorTransactionsPageState();
}

class _MonitorTransactionsPageState extends State<MonitorTransactionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    // 3 tabs: All, Completed, Failed
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTransactions();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedTransaction = null;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await NetworkDataService.getMonitorTransactions();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_tabController.index == 0) return _transactions; // All
    
    if (_tabController.index == 1) { // Completed
      return _transactions.where((t) {
        final status = '${t['status']}'.toLowerCase();
        return status == 'completed' || status == 'fulfilled_by_neighbor';
      }).toList();
    }
    
    // Failed (Expired / No Matches)
    return _transactions.where((t) {
      final status = '${t['status']}'.toLowerCase();
      return status != 'completed' && status != 'fulfilled_by_neighbor';
    }).toList();
  }

  String _formatTime(dynamic isoString) {
    if (isoString == null || isoString.toString().isEmpty) return 'Unknown Time';
    try {
      final dt = DateTime.parse(isoString.toString()).toLocal();
      return DateFormat('MMM d, HH:mm').format(dt);
    } catch (_) {
      return isoString.toString();
    }
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
            NavLink(label: 'Pharmacies', path: '/admin/pharmacies'),
            NavLink(label: 'Transactions', path: '/admin/transactions', active: true),
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
                              onPressed: _loadTransactions,
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
                                    tabs: const [
                                      Tab(text: 'All'),
                                      Tab(text: 'Completed'),
                                      Tab(text: 'Failed'),
                                    ],
                                  ),
                                  Expanded(
                                    child: _filteredTransactions.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No transactions found in this category.',
                                              style: TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: const EdgeInsets.all(12),
                                            itemCount: _filteredTransactions.length,
                                            separatorBuilder: (context, index) => const Divider(color: Color(0x80B4B2A9), height: 1),
                                            itemBuilder: (context, index) {
                                              final txn = _filteredTransactions[index];
                                              final isSelected = _selectedTransaction?['id'] == txn['id'];
                                              
                                              final status = '${txn['status']}'.toLowerCase();
                                              final isCompleted = status == 'completed' || status == 'fulfilled_by_neighbor';
                                              
                                              return ListTile(
                                                selected: isSelected,
                                                selectedTileColor: const Color(0xFFE2F3EE),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                title: Text(
                                                  '${txn['drug']} x${txn['quantity'] ?? 'N/A'}', 
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A18))
                                                ),
                                                subtitle: Text(
                                                  _formatTime(txn['time']), 
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF5F5E5A))
                                                ),
                                                trailing: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isCompleted ? const Color(0xFFE1F5EE) : const Color(0xFFFAEEDA),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${txn['status']}'.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                      color: isCompleted ? const Color(0xFF085041) : const Color(0xFF633806),
                                                    ),
                                                  ),
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedTransaction = txn;
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right Panel (Detail Card)
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: const Color(0xFFF9F8F6),
                              padding: const EdgeInsets.all(24),
                              child: _selectedTransaction == null
                                  ? const Center(
                                      child: Text(
                                        'Select a transaction to view manifest',
                                        style: TextStyle(fontSize: 14, color: Color(0xFF5F5E5A)),
                                      ),
                                    )
                                  : _buildManifestCard(_selectedTransaction!),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestCard(Map<String, dynamic> txn) {
    final status = '${txn['status']}'.toLowerCase();
    final isCompleted = status == 'completed' || status == 'fulfilled_by_neighbor';

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x80B4B2A9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Digital Transfer Manifest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A18)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFE1F5EE) : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${txn['status']}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF085041) : const Color(0xFF633806),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildManifestRow('Manifest ID', '${txn['id']}'),
            const Divider(color: Color(0x80B4B2A9), height: 24),
            _buildManifestRow('Timestamp', _formatTime(txn['time'])),
            const Divider(color: Color(0x80B4B2A9), height: 24),
            _buildManifestRow('Requesting Pharmacy', '${txn['to']}'),
            const Divider(color: Color(0x80B4B2A9), height: 24),
            _buildManifestRow('Supplying Pharmacy', '${txn['from']}'),
            const Divider(color: Color(0x80B4B2A9), height: 24),
            _buildManifestRow('Drug Requested', '${txn['drug']}'),
            const Divider(color: Color(0x80B4B2A9), height: 24),
            _buildManifestRow('Quantity', '${txn['quantity'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F5E5A)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A18)),
          ),
        ),
      ],
    );
  }
}
