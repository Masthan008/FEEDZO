import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/cuisine_model.dart';
import '../services/cuisine_service.dart';
import '../widgets/topbar.dart';

class CuisinesScreen extends StatefulWidget {
  const CuisinesScreen({super.key});

  @override
  State<CuisinesScreen> createState() => _CuisinesScreenState();
}

class _CuisinesScreenState extends State<CuisinesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  int _priority = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({CuisineModel? cuisine}) {
    if (cuisine != null) {
      _nameController.text = cuisine.name;
      _descriptionController.text = cuisine.description ?? '';
      _imageUrlController.text = cuisine.imageUrl ?? '';
      _priority = cuisine.priority;
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _priority = 0;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(cuisine == null ? 'Add New Cuisine' : 'Edit Cuisine'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cuisine Name *',
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
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _priority,
                      onChanged: (v) => setDialogState(() => _priority = v!),
                    ),
                    const Text('Normal'),
                    const SizedBox(width: 16),
                    Radio<int>(
                      value: 1,
                      groupValue: _priority,
                      onChanged: (v) => setDialogState(() => _priority = v!),
                    ),
                    const Text('Medium'),
                    const SizedBox(width: 16),
                    Radio<int>(
                      value: 2,
                      groupValue: _priority,
                      onChanged: (v) => setDialogState(() => _priority = v!),
                    ),
                    const Text('High'),
                  ],
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
                    const SnackBar(content: Text('Cuisine name is required')),
                  );
                  return;
                }

                final cuisineData = CuisineModel(
                  id: cuisine?.id ?? '',
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  imageUrl: _imageUrlController.text.trim(),
                  priority: _priority,
                  isActive: cuisine?.isActive ?? true,
                  createdAt: cuisine?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (cuisine == null) {
                    await CuisineService.addCuisine(cuisineData);
                  } else {
                    await CuisineService.updateCuisine(cuisineData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          cuisine == null
                              ? 'Cuisine added successfully'
                              : 'Cuisine updated successfully',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Cuisine Management', subtitle: 'Manage food cuisines'),
        Expanded(
          child: StreamBuilder<List<CuisineModel>>(
            stream: CuisineService.watchAllCuisines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final cuisines = snapshot.data ?? [];

              if (cuisines.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No cuisines added yet', style: TextStyle(color: Colors.grey)),
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
                  itemCount: cuisines.length,
                  itemBuilder: (context, index) {
                    final cuisine = cuisines[index];
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
                                    cuisine.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (cuisine.priority > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(cuisine.priority),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getPriorityLabel(cuisine.priority),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (cuisine.description != null)
                              Text(
                                cuisine.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showAddEditDialog(cuisine: cuisine),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(
                                    cuisine.isActive ? Icons.toggle_on : Icons.toggle_off,
                                    size: 18,
                                    color: cuisine.isActive ? Colors.green : Colors.red,
                                  ),
                                  onPressed: () async {
                                    await CuisineService.toggleCuisineStatus(
                                      cuisine.id,
                                      !cuisine.isActive,
                                    );
                                  },
                                  tooltip: cuisine.isActive ? 'Deactivate' : 'Activate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Cuisine'),
                                        content: Text(
                                          'Are you sure you want to delete "${cuisine.name}"?',
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
                                      await CuisineService.deleteCuisine(cuisine.id);
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
              label: const Text('Add New Cuisine'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Normal';
    }
  }
}
