import 'package:flutter/material.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/network_data_service.dart';

class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({super.key});

  @override
  State<ManageInventoryPage> createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;

  final _drugNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  @override
  void dispose() {
    _drugNameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final data = await NetworkDataService.getMyInventory();
      setState(() {
        _inventory = data;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load inventory.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String itemId, int currentQty, int delta) async {
    final newQty = currentQty + delta;
    if (newQty < 0) return; // Prevent negative stock

    // Optimistic update
    setState(() {
      final index = _inventory.indexWhere((item) => '${item['item_id'] ?? item['id']}' == itemId);
      if (index != -1) {
        _inventory[index]['stock_quantity'] = newQty;
      }
    });

    try {
      await NetworkDataService.updateInventoryQuantity(itemId, newQty);
    } catch (_) {
      // Revert on failure
      setState(() {
        final index = _inventory.indexWhere((item) => '${item['item_id'] ?? item['id']}' == itemId);
        if (index != -1) {
          _inventory[index]['stock_quantity'] = currentQty;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update quantity.')),
      );
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to remove this drug from your inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFA32D2D)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await NetworkDataService.deleteInventoryItem(itemId);
      await _fetchInventory();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item.')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final name = _drugNameController.text.trim();
    final qtyText = _quantityController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty || qtyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Quantity are required.')),
      );
      return;
    }

    final qty = int.tryParse(qtyText);
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a valid positive number.')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await NetworkDataService.addInventoryItem({
        'drug_name': name,
        'stock_quantity': qty,
        'drug_category': category.isEmpty ? 'General' : category,
      });
      
      _drugNameController.clear();
      _quantityController.clear();
      _categoryController.clear();
      
      await _fetchInventory();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item.')),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Inventory', path: '/inventory', active: true),
          ]),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: List
                Expanded(
                  flex: 2,
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
                            'My Inventory',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_inventory.isEmpty)
                            const Text(
                              'Your inventory is empty.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5F5E5A),
                              ),
                            )
                          else
                            ..._inventory.map((item) {
                              final itemId = '${item['item_id'] ?? item['id'] ?? ''}';
                              final name = '${item['drug_name'] ?? item['drug'] ?? 'Unknown'}';
                              final category = '${item['drug_category'] ?? 'General'}';
                              final qty = int.tryParse('${item['stock_quantity'] ?? item['quantity'] ?? '0'}') ?? 0;
                              
                              return Container(
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
                                            name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A18),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF5F5E5A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: const Color(0xFF1D9E75),
                                          iconSize: 18,
                                          onPressed: qty > 0 ? () => _updateQuantity(itemId, qty, -1) : null,
                                        ),
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '$qty',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          color: const Color(0xFF1D9E75),
                                          iconSize: 18,
                                          onPressed: () => _updateQuantity(itemId, qty, 1),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          color: const Color(0xFFA32D2D),
                                          iconSize: 18,
                                          onPressed: () => _deleteItem(itemId),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Column: Add Form
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 14, right: 14, bottom: 14),
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
                            'Add New Drug',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _drugNameController,
                            placeholder: 'Drug Name (e.g., Amoxicillin 500mg)',
                          ),
                          AppTextField(
                            controller: _quantityController,
                            placeholder: 'Initial Quantity',
                            keyboardType: TextInputType.number,
                          ),
                          AppTextField(
                            controller: _categoryController,
                            placeholder: 'Category (Optional)',
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            text: _isAdding ? 'Adding...' : 'Add to Inventory',
                            onPressed: _isAdding ? () {} : _addItem,
                          ),
                        ],
                      ),
                    ),
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
