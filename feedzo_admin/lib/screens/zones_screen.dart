import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/zone_model.dart';
import '../services/zone_service.dart';
import '../widgets/topbar.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _baseChargeController = TextEditingController(text: '20.0');
  final _perKmChargeController = TextEditingController(text: '5.0');
  final _minOrderController = TextEditingController(text: '100.0');

  List<double> _coordinates = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _baseChargeController.dispose();
    _perKmChargeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({ZoneModel? zone}) {
    if (zone != null) {
      _nameController.text = zone.name;
      _descriptionController.text = zone.description ?? '';
      _baseChargeController.text = zone.baseDeliveryCharge.toString();
      _perKmChargeController.text = zone.perKmCharge.toString();
      _minOrderController.text = zone.minOrderValue.toString();
      _coordinates = List.from(zone.coordinates);
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _baseChargeController.text = '20.0';
      _perKmChargeController.text = '5.0';
      _minOrderController.text = '100.0';
      _coordinates = [];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(zone == null ? 'Add New Zone' : 'Edit Zone'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Zone Name *',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _baseChargeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Base Delivery Charge (₹) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _perKmChargeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Per KM Charge (₹) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Order Value (₹) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zone Coordinates',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click on map to set zone center point',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (_coordinates.isNotEmpty)
                          Text(
                            'Lat: ${_coordinates[0].toStringAsFixed(6)}, Lng: ${_coordinates[1].toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Integrate map picker
                            setDialogState(() {
                              _coordinates = [12.9716, 77.5946]; // Default Bangalore
                            });
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Select on Map'),
                        ),
                      ],
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
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zone name is required')),
                  );
                  return;
                }

                final zoneData = ZoneModel(
                  id: zone?.id ?? '',
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  coordinates: _coordinates,
                  baseDeliveryCharge:
                      double.tryParse(_baseChargeController.text) ?? 20.0,
                  perKmCharge:
                      double.tryParse(_perKmChargeController.text) ?? 5.0,
                  minOrderValue:
                      double.tryParse(_minOrderController.text) ?? 100.0,
                  isActive: zone?.isActive ?? true,
                  createdAt: zone?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (zone == null) {
                    await ZoneService.addZone(zoneData);
                  } else {
                    await ZoneService.updateZone(zoneData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          zone == null
                              ? 'Zone added successfully'
                              : 'Zone updated successfully',
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
        const TopBar(title: 'Zone Management', subtitle: 'Manage delivery zones'),
        Expanded(
          child: StreamBuilder<List<ZoneModel>>(
            stream: ZoneService.watchAllZones(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final zones = snapshot.data ?? [];

              if (zones.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_city_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No zones added yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: zones.length,
                  itemBuilder: (context, index) {
                    final zone = zones[index];
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
                                    zone.name,
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
                                    color: zone.isActive
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    zone.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: zone.isActive
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (zone.description != null)
                              Text(
                                zone.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '₹${zone.baseDeliveryCharge.toStringAsFixed(0)} + ₹${zone.perKmCharge.toStringAsFixed(0)}/km',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showAddEditDialog(zone: zone),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(
                                    zone.isActive ? Icons.toggle_on : Icons.toggle_off,
                                    size: 18,
                                    color: zone.isActive ? Colors.green : Colors.red,
                                  ),
                                  onPressed: () async {
                                    await ZoneService.toggleZoneStatus(
                                      zone.id,
                                      !zone.isActive,
                                    );
                                  },
                                  tooltip: zone.isActive ? 'Deactivate' : 'Activate',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Zone'),
                                        content: Text(
                                          'Are you sure you want to delete "${zone.name}"?',
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
                                      await ZoneService.deleteZone(zone.id);
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
              label: const Text('Add New Zone'),
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
