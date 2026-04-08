import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/restaurant_admin_service.dart';
import '../../services/hike_charges_service.dart';
import '../../services/monthly_report_service.dart';
import '../../data/models.dart';

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
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Monthly Report',
            onPressed: () => _showMonthlyReportDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.price_change_outlined),
            tooltip: 'Hike Charges',
            onPressed: () => _showHikeChargesDialog(),
          ),
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

  // ═════════════════════════════════════════════════════════════════════════════
  // MONTHLY REPORT DIALOG
  // ═════════════════════════════════════════════════════════════════════════════

  Future<void> _showMonthlyReportDialog() async {
    final now = DateTime.now();
    DateTime selectedMonth = DateTime(now.year, now.month - 1, 1);
    bool isGenerating = false;
    String? generatedUrl;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly Report - ${widget.restaurantName}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Report for: ${DateFormat('MMMM yyyy').format(selectedMonth)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedMonth,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            helpText: 'Select Month for Report',
                            selectableDayPredicate: (day) => day.day == 1,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedMonth = DateTime(picked.year, picked.month, 1));
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (generatedUrl == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setDialogState(() => isGenerating = true);
                              final url = await MonthlyReportService.generateAndUploadReport(
                                restaurantId: widget.restaurantId,
                                restaurantName: widget.restaurantName,
                                month: selectedMonth,
                              );
                              setDialogState(() {
                                isGenerating = false;
                                generatedUrl = url;
                              });
                            },
                      icon: isGenerating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_circle_outline),
                      label: Text(isGenerating ? 'Generating...' : 'Generate Report'),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 40),
                        const SizedBox(height: 12),
                        const Text('Report Generated Successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('View Report'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Previous Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: MonthlyReportService.watchReportHistory(widget.restaurantId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reports = snapshot.data ?? [];
                      if (reports.isEmpty) {
                        return Center(child: Text('No previous reports', style: TextStyle(color: Colors.grey.shade600)));
                      }
                      return ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final month = (report['month'] as Timestamp).toDate();
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                            title: Text(DateFormat('MMMM yyyy').format(month)),
                            subtitle: Text('Orders: ${report['totalOrders'] ?? 0} | Value: ₹${(report['totalOrderValue'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(icon: const Icon(Icons.download, size: 18), onPressed: () {}),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      ),
    );
  }

  Future<void> _showHikeChargesDialog() async {
    final override = await HikeChargesService.getRestaurantOverride(widget.restaurantId);
    final globalConfig = await HikeChargesService.getGlobalConfig();
    bool useGlobal = override?.useGlobalSettings ?? true;
    final hikeCtrl = TextEditingController(text: (override?.customHikeMultiplier ?? globalConfig?.hikeMultiplier ?? 10).toString());
    final packagingCtrl = TextEditingController(text: (override?.customPackagingCharges ?? globalConfig?.packagingCharges ?? 10).toString());
    final deliveryCtrl = TextEditingController(text: (override?.customDeliveryCharges ?? globalConfig?.deliveryCharges ?? 20).toString());

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.price_change_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('Hike Charges - ${widget.restaurantName}', style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: useGlobal ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: useGlobal ? Colors.green.shade200 : Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(useGlobal ? 'Using Global Settings' : 'Custom Settings', style: TextStyle(fontWeight: FontWeight.bold, color: useGlobal ? Colors.green.shade700 : Colors.orange.shade700)),
                            Text(useGlobal ? 'Restaurant follows system-wide hike charge settings' : 'Restaurant has custom hike charge settings', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Switch(value: useGlobal, onChanged: (v) => setDialogState(() => useGlobal = v), activeColor: Colors.green),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!useGlobal) ...[
                  const Text('Custom Hike Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: packagingCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Packaging Charges (₹)', prefixIcon: Icon(Icons.shopping_bag_outlined), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deliveryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Delivery Charges (₹)', prefixIcon: Icon(Icons.delivery_dining_outlined), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hikeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hike Multiplier (%)', prefixIcon: Icon(Icons.trending_up_outlined), border: OutlineInputBorder(), helperText: 'Percentage added during peak hours'),
                  ),
                ],
                const SizedBox(height: 16),
                if (globalConfig != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Global Settings (Reference)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Packaging: ₹${globalConfig.packagingCharges}'),
                        Text('Delivery: ₹${globalConfig.deliveryCharges}'),
                        Text('Hike Multiplier: ${globalConfig.hikeMultiplier}%'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newOverride = RestaurantHikeOverride(
                  restaurantId: widget.restaurantId,
                  useGlobalSettings: useGlobal,
                  customPackagingCharges: double.tryParse(packagingCtrl.text) ?? globalConfig?.packagingCharges ?? 10,
                  customDeliveryCharges: double.tryParse(deliveryCtrl.text) ?? globalConfig?.deliveryCharges ?? 20,
                  customHikeMultiplier: double.tryParse(hikeCtrl.text) ?? globalConfig?.hikeMultiplier ?? 10,
                  updatedAt: DateTime.now(),
                );
                await HikeChargesService.saveRestaurantOverride(newOverride);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(useGlobal ? 'Now using global hike charge settings' : 'Custom hike charges saved for ${widget.restaurantName}'),
                      backgroundColor: useGlobal ? Colors.green : AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
