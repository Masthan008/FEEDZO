import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedRestaurant = '';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Inventory Management',
          subtitle: 'Manage restaurant inventory',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Metrics cards
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('inventory').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data?.docs ?? [];
            
            int totalItems = items.length;
            int lowStock = 0;
            int outOfStock = 0;
            double stockValue = 0;

            for (var itemDoc in items) {
              final data = itemDoc.data() as Map<String, dynamic>;
              final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
              final minStock = (data['minStock'] as num?)?.toInt() ?? 0;
              final price = (data['price'] as num?)?.toDouble() ?? 0;

              if (quantity == 0) {
                outOfStock++;
              } else if (quantity <= minStock) {
                lowStock++;
              }

              stockValue += quantity * price;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 140,
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildInventoryCard(
                      title: 'Total Items',
                      icon: Icons.restaurant_menu,
                      color: Colors.blue,
                      value: totalItems.toString(),
                      subtitle: 'Items tracked',
                    ),
                    _buildInventoryCard(
                      title: 'Low Stock',
                      icon: Icons.warning,
                      color: Colors.orange,
                      value: lowStock.toString(),
                      subtitle: 'Need reorder',
                    ),
                    _buildInventoryCard(
                      title: 'Out of Stock',
                      icon: Icons.block,
                      color: Colors.red,
                      value: outOfStock.toString(),
                      subtitle: 'Unavailable',
                    ),
                    _buildInventoryCard(
                      title: 'Stock Value',
                      icon: Icons.inventory_2,
                      color: Colors.green,
                      value: '₹${_formatCurrency(stockValue)}',
                      subtitle: 'Total value',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Inventory list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('inventory')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final items = snapshot.data?.docs ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No inventory items yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Item Name')),
                    DataColumn(label: Text('Restaurant')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Min Stock')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: items.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
                    final minStock = (data['minStock'] as num?)?.toInt() ?? 0;
                    final price = (data['price'] as num?)?.toDouble() ?? 0;

                    String status;
                    Color statusColor;
                    if (quantity == 0) {
                      status = 'Out of Stock';
                      statusColor = Colors.red;
                    } else if (quantity <= minStock) {
                      status = 'Low Stock';
                      statusColor = Colors.orange;
                    } else {
                      status = 'In Stock';
                      statusColor = Colors.green;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(data['name'] ?? 'N/A')),
                        DataCell(Text(data['restaurantName'] ?? 'N/A')),
                        DataCell(Text(quantity.toString())),
                        DataCell(Text(minStock.toString())),
                        DataCell(Text('₹${price.toStringAsFixed(0)}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: Colors.green),
                                onPressed: () => _adjustStock(doc, 1),
                                tooltip: 'Add Stock',
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18, color: Colors.orange),
                                onPressed: () => _adjustStock(doc, -1),
                                tooltip: 'Remove Stock',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditDialog(doc),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _deleteItem(doc.id),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _quantityController.clear();
    _minStockController.clear();
    _priceController.clear();
    _selectedRestaurant = '';

    await _showInventoryDialog(null);
  }

  Future<void> _showEditDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _quantityController.text = (data['quantity'] ?? 0).toString();
    _minStockController.text = (data['minStock'] ?? 0).toString();
    _priceController.text = (data['price'] ?? 0).toString();
    _selectedRestaurant = data['restaurantId'] ?? '';

    await _showInventoryDialog(doc.id);
  }

  Future<void> _showInventoryDialog(String? docId) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? 'Add Inventory Item' : 'Edit Inventory Item'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
                    builder: (context, snapshot) {
                      final restaurants = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: _selectedRestaurant.isEmpty ? null : _selectedRestaurant,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant *',
                          border: OutlineInputBorder(),
                        ),
                        items: restaurants.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['name'] ?? 'N/A'),
                          );
                        }).toList(),
                    onChanged: docId == null ? (v) => setDialogState(() => _selectedRestaurant = v!) : null,
                  );
                },
              ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Alert',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveItem(docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem(String? docId) async {
    if (_nameController.text.isEmpty || _quantityController.text.isEmpty || _selectedRestaurant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, quantity, and restaurant are required')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    // Get restaurant name
    final restaurantDoc = await FirebaseFirestore.instance.collection('restaurants').doc(_selectedRestaurant).get();
    final restaurantData = restaurantDoc.data() as Map<String, dynamic>? ?? {};
    final restaurantName = restaurantData['name'] ?? 'N/A';

    final itemData = {
      'name': _nameController.text.trim(),
      'restaurantId': _selectedRestaurant,
      'restaurantName': restaurantName,
      'quantity': quantity,
      'minStock': minStock,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (docId == null) {
        await FirebaseFirestore.instance.collection('inventory').add(itemData);
      } else {
        await FirebaseFirestore.instance.collection('inventory').doc(docId).update(itemData);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docId == null ? 'Item added successfully' : 'Item updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adjustStock(DocumentSnapshot doc, int adjustment) async {
    final data = doc.data() as Map<String, dynamic>;
    final currentQuantity = (data['quantity'] as num?)?.toInt() ?? 0;
    final newQuantity = (currentQuantity + adjustment).clamp(0, double.infinity).toInt();

    await doc.reference.update({
      'quantity': newQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteItem(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this inventory item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('inventory').doc(docId).delete();
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildInventoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
