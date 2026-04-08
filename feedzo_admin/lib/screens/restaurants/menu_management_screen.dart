import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../services/restaurant_admin_service.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final RestaurantAdminService _service = RestaurantAdminService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showItemDialog([Map<String, dynamic>? item]) async {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final priceCtrl = TextEditingController(
      text: item?['price']?.toString() ?? '',
    );
    final discountCtrl = TextEditingController(
      text: item?['discount']?.toString() ?? '0',
    );
    final imageUrlCtrl = TextEditingController(text: item?['imageUrl'] ?? '');
    
    String category = item?['category'] ?? 'Main Course';
    bool isAvailable = item?['isAvailable'] ?? true;
    bool isVeg = item?['isVeg'] ?? true;
    bool isBestseller = item?['isBestseller'] ?? false;

    final categories = [
      'Appetizers',
      'Main Course',
      'Biryani',
      'Desserts',
      'Beverages',
      'Starters',
      'Soups',
      'Salads',
      'Bread',
      'Rice',
      'Chinese',
      'South Indian',
      'North Indian',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Margherita Pizza',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Fresh mozzarella, tomato sauce, basil',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children: [
                    FilterChip(
                      label: const Text('Vegetarian'),
                      selected: isVeg,
                      onSelected: (v) => setDialogState(() => isVeg = v),
                    ),
                    FilterChip(
                      label: const Text('Available'),
                      selected: isAvailable,
                      onSelected: (v) => setDialogState(() => isAvailable = v),
                    ),
                    FilterChip(
                      label: const Text('Bestseller'),
                      selected: isBestseller,
                      onSelected: (v) => setDialogState(() => isBestseller = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and Price are required')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final price = double.tryParse(priceCtrl.text) ?? 0;
      final discount = double.tryParse(discountCtrl.text) ?? 0;

      if (isEditing) {
        await _service.updateMenuItem(
          widget.restaurantId,
          item['id'],
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: price,
          discount: discount,
          isAvailable: isAvailable,
          isVeg: isVeg,
          category: category,
          isBestseller: isBestseller,
          imageUrl: imageUrlCtrl.text.trim(),
        );
      } else {
        await _service.addMenuItem(
          widget.restaurantId,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          price: price,
          discount: discount,
          isAvailable: isAvailable,
          isVeg: isVeg,
          category: category,
          isBestseller: isBestseller,
          imageUrl: imageUrlCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Item updated' : 'Item added'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId, String itemName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteMenuItem(widget.restaurantId, itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  Future<void> _toggleAvailability(String itemId, bool currentStatus) async {
    await _service.toggleMenuItemAvailability(
      widget.restaurantId,
      itemId,
      !currentStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.restaurantName}'),
            const Text(
              'Menu Management',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showItemDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category chips
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.getMenuItems(widget.restaurantId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final items = snapshot.data!;
                    final categories = ['All', ...items.map((i) => i['category'] ?? 'Other').toSet().toList()];
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (v) => setState(() => _selectedCategory = cat),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _selectedCategory == cat ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        )).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Menu List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getMenuItems(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error.withAlpha(150)),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading menu',
                          style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                
                // Filter items
                var filteredItems = items.where((item) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      (item['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                      (item['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  
                  final matchesCategory = _selectedCategory == 'All' ||
                      item['category'] == _selectedCategory;
                  
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items found',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _MenuItemCard(
                      item: item,
                      onEdit: () => _showItemDialog(item),
                      onDelete: () => _deleteItem(item['id'], item['name'] ?? ''),
                      onToggleAvailability: () => _toggleAvailability(
                        item['id'],
                        item['isAvailable'] ?? true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? 'Unknown';
    final description = item['description'] ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final discount = (item['discount'] as num?)?.toDouble() ?? 0;
    final isAvailable = item['isAvailable'] ?? true;
    final isVeg = item['isVeg'] ?? true;
    final isBestseller = item['isBestseller'] ?? false;
    final category = item['category'] ?? 'Main Course';
    final imageUrl = item['imageUrl'] as String?;

    final discountedPrice = discount > 0
        ? price * (1 - discount / 100)
        : price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.surface,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(isVeg),
                      )
                    : _buildPlaceholder(isVeg),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Veg/Non-veg indicator
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isVeg ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Bestseller badge
                      if (isBestseller)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bestseller',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Category
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Row(
                    children: [
                      if (discount > 0) ...[
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '₹${discountedPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${discount.toStringAsFixed(0)}% OFF',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              children: [
                // Availability Toggle
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeColor: AppColors.statusDelivered,
                ),
                Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    color: isAvailable ? AppColors.statusDelivered : AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Edit/Delete
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      color: AppColors.info,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: AppColors.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isVeg) {
    return Center(
      child: Icon(
        isVeg ? Icons.eco : Icons.restaurant,
        color: isVeg ? Colors.green : Colors.red,
        size: 32,
      ),
    );
  }
}
