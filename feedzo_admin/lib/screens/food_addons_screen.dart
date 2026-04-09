import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/food_addon_model.dart';
import '../services/food_addon_service.dart';
import '../widgets/topbar.dart';

class FoodAddonsScreen extends StatefulWidget {
  const FoodAddonsScreen({super.key});

  @override
  State<FoodAddonsScreen> createState() => _FoodAddonsScreenState();
}

class _FoodAddonsScreenState extends State<FoodAddonsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0.0');
  String? _selectedRestaurantId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({FoodAddonModel? addon}) {
    if (addon != null) {
      _nameController.text = addon.name;
      _descriptionController.text = addon.description ?? '';
      _priceController.text = addon.price.toString();
      _selectedRestaurantId = addon.restaurantId;
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.text = '0.0';
      _selectedRestaurantId = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(addon == null ? 'Add New Addon' : 'Edit Addon'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Addon Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Restaurant (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedRestaurantId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Restaurants (Global)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Restaurants (Global)'),
                      ),
                      ...snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name'] ?? 'Unknown'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRestaurantId = value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Addon name is required')),
                );
                return;
              }

              final addonData = FoodAddonModel(
                id: addon?.id ?? '',
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                price: double.tryParse(_priceController.text) ?? 0.0,
                restaurantId: _selectedRestaurantId,
                isActive: addon?.isActive ?? true,
                createdAt: addon?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                if (addon == null) {
                  await FoodAddonService.addAddon(addonData);
                } else {
                  await FoodAddonService.updateAddon(addonData);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        addon == null
                            ? 'Addon added successfully'
                            : 'Addon updated successfully',
                      ),
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Food Addons', subtitle: 'Manage food customization options'),
        Expanded(
          child: StreamBuilder<List<FoodAddonModel>>(
            stream: FoodAddonService.watchAllAddons(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final addons = snapshot.data ?? [];

              if (addons.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No addons added yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: addons.length,
                  itemBuilder: (context, index) {
                    final addon = addons[index];
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    addon.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: addon.isActive
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    addon.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: addon.isActive
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${addon.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (addon.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                addon.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (addon.restaurantId != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Restaurant Specific',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showAddEditDialog(addon: addon),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(
                                    addon.isActive ? Icons.toggle_on : Icons.toggle_off,
                                    size: 18,
                                    color: addon.isActive ? Colors.green : Colors.red,
                                  ),
                                  onPressed: () async {
                                    await FoodAddonService.toggleAddonStatus(
                                      addon.id,
                                      !addon.isActive,
                                    );
                                  },
                                  tooltip: addon.isActive ? 'Deactivate' : 'Activate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Addon'),
                                        content: Text(
                                          'Are you sure you want to delete "${addon.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FoodAddonService.deleteAddon(addon.id);
                                    }
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add New Addon'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
