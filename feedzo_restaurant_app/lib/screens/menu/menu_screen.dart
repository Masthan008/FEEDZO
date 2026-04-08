import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/cloudinary_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final filtered = provider.items.where((i) {
      final matchesSearch =
          i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showItemDialog(context, null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (provider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const Expanded(child: Center(child: Text('No menu items found.')))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _MenuItemCard(
                  item: filtered[i],
                  onEdit: () => _showItemDialog(context, filtered[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, MenuItemModel? item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MenuItemForm(item: item),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onEdit;
  const _MenuItemCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MenuProvider>();
    final hasDiscount = item.discount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        item.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: item.isVeg ? Colors.green : Colors.red,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: item.isVeg ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (item.isBestseller)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'BESTSELLER',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '₹${item.discountedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      // Stock Status Indicator
                      if (item.trackInventory) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isOutOfStock
                                ? Colors.red.shade50
                                : item.isLowStock
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.isOutOfStock
                                  ? Colors.red
                                  : item.isLowStock
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isOutOfStock
                                    ? Icons.error
                                    : item.isLowStock
                                        ? Icons.warning
                                        : Icons.check_circle,
                                size: 14,
                                color: item.isOutOfStock
                                    ? Colors.red
                                    : item.isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isOutOfStock
                                    ? 'Out of Stock'
                                    : item.isLowStock
                                        ? 'Low Stock: ${item.stockQuantity}'
                                        : 'Stock: ${item.stockQuantity}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.isOutOfStock
                                      ? Colors.red
                                      : item.isLowStock
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Switch(
                      value: item.isAvailable,
                      onChanged: (v) => provider.toggleAvailability(item.id, v),
                      activeColor: AppColors.primary,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, provider, item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasDiscount)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.discount.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (!item.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'NOT AVAILABLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to remove this item from the menu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteItem(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemForm extends StatefulWidget {
  final MenuItemModel? item;
  const _MenuItemForm({this.item});

  @override
  State<_MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<_MenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _lowStockCtrl;

  File? _imageFile;
  String? _currentImageUrl;
  bool _isSaving = false;
  bool _isVeg = true;
  bool _isBestseller = false;
  bool _trackInventory = false;
  bool _unlimitedStock = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _descCtrl = TextEditingController(text: widget.item?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.item?.price.toStringAsFixed(0) ?? '',
    );
    _discountCtrl = TextEditingController(
      text: widget.item?.discount.toStringAsFixed(0) ?? '',
    );
    _categoryCtrl = TextEditingController(
      text: widget.item?.category ?? 'Main Course',
    );
    _stockCtrl = TextEditingController(
      text: widget.item?.stockQuantity.toString() ?? '10',
    );
    _lowStockCtrl = TextEditingController(
      text: widget.item?.lowStockThreshold.toString() ?? '5',
    );
    _currentImageUrl = widget.item?.imageUrl;
    _isVeg = widget.item?.isVeg ?? true;
    _isBestseller = widget.item?.isBestseller ?? false;
    _trackInventory = widget.item?.trackInventory ?? false;
    _unlimitedStock = widget.item?.unlimitedStock ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _currentImageUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _currentImageUrl;
      if (_imageFile != null) {
        imageUrl = await CloudinaryService.uploadImage(
          _imageFile!,
          folder: 'menu_items',
        );
      }

      if (imageUrl == null) throw 'Failed to upload image';

      final provider = context.read<MenuProvider>();
      final user = FirebaseAuth.instance.currentUser;

      final stockQty = int.tryParse(_stockCtrl.text) ?? 10;
      final lowStock = int.tryParse(_lowStockCtrl.text) ?? 5;

      if (widget.item == null) {
        await provider.addItem(
          MenuItemModel(
            id: '',
            restaurantId: user!.uid,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.parse(_priceCtrl.text),
            discount: double.tryParse(_discountCtrl.text) ?? 0.0,
            isAvailable: _unlimitedStock || stockQty > 0,
            imageUrl: imageUrl,
            isVeg: _isVeg,
            category: _categoryCtrl.text.trim(),
            isBestseller: _isBestseller,
            trackInventory: _trackInventory,
            unlimitedStock: _unlimitedStock,
            stockQuantity: _unlimitedStock ? -1 : stockQty,
            lowStockThreshold: lowStock,
          ),
        );
      } else {
        await provider.updateItem(
          MenuItemModel(
            id: widget.item!.id,
            restaurantId: widget.item!.restaurantId,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.parse(_priceCtrl.text),
            discount: double.tryParse(_discountCtrl.text) ?? 0.0,
            isAvailable: widget.item!.isAvailable,
            imageUrl: imageUrl,
            isVeg: _isVeg,
            category: _categoryCtrl.text.trim(),
            isBestseller: _isBestseller,
            trackInventory: _trackInventory,
            unlimitedStock: _unlimitedStock,
            stockQuantity: _unlimitedStock ? -1 : stockQty,
            lowStockThreshold: lowStock,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item == null ? 'Add New Item' : 'Edit Item',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : (_currentImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                )),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Grilled Chicken Burger',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Spicy chicken patty with lettuce and mayo',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Burgers, Starters, Drinks',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        prefixText: '₹ ',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount (%)',
                        suffixText: '%',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Veg Item',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v),
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bestseller Tag',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isBestseller,
                    onChanged: (v) => setState(() => _isBestseller = v),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Inventory Management Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, 
                              color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Inventory Tracking',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _trackInventory,
                          onChanged: (v) => setState(() {
                            _trackInventory = v;
                            if (!v) _unlimitedStock = true;
                          }),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                    if (_trackInventory) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Unlimited Stock',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _unlimitedStock,
                            onChanged: (v) => setState(() => _unlimitedStock = v),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      if (!_unlimitedStock) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Current Stock',
                                  hintText: '10',
                                  prefixIcon: Icon(Icons.store),
                                ),
                                validator: (v) {
                                  if (!_unlimitedStock && (v == null || v.isEmpty)) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lowStockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Low Stock Alert',
                                  hintText: '5',
                                  prefixIcon: Icon(Icons.warning),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Item will be auto-marked unavailable when stock reaches 0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
