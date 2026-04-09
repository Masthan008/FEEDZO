import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/app_version_model.dart';
import '../services/app_version_service.dart';
import '../widgets/topbar.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  final _versionController = TextEditingController();
  final _buildNumberController = TextEditingController(text: '1');
  final _messageController = TextEditingController();
  final _downloadUrlController = TextEditingController();
  String _platform = 'android';
  bool _isForceUpdate = false;
  bool _isActive = true;

  @override
  void dispose() {
    _versionController.dispose();
    _buildNumberController.dispose();
    _messageController.dispose();
    _downloadUrlController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({AppVersionModel? version}) {
    if (version != null) {
      _versionController.text = version.version;
      _buildNumberController.text = version.buildNumber.toString();
      _messageController.text = version.updateMessage ?? '';
      _downloadUrlController.text = version.downloadUrl ?? '';
      _platform = version.platform;
      _isForceUpdate = version.isForceUpdate;
      _isActive = version.isActive;
    } else {
      _versionController.clear();
      _buildNumberController.text = '1';
      _messageController.clear();
      _downloadUrlController.clear();
      _platform = 'android';
      _isForceUpdate = false;
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(version == null ? 'Add App Version' : 'Edit App Version'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _platform,
                    decoration: const InputDecoration(
                      labelText: 'Platform *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'android', child: Text('Android')),
                      DropdownMenuItem(value: 'ios', child: Text('iOS')),
                    ],
                    onChanged: (v) => setDialogState(() => _platform = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _versionController,
                    decoration: const InputDecoration(
                      labelText: 'Version *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 1.0.0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _buildNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Build Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Update Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _downloadUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Download URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Force Update'),
                    subtitle: const Text('Users must update to continue using the app'),
                    value: _isForceUpdate,
                    onChanged: (v) => setDialogState(() => _isForceUpdate = v),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('This version is currently available'),
                    value: _isActive,
                    onChanged: (v) => setDialogState(() => _isActive = v),
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
                if (_versionController.text.isEmpty || _buildNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Version and build number are required')),
                  );
                  return;
                }

                final versionData = AppVersionModel(
                  id: version?.id ?? '',
                  platform: _platform,
                  version: _versionController.text.trim(),
                  buildNumber: int.tryParse(_buildNumberController.text) ?? 1,
                  isForceUpdate: _isForceUpdate,
                  updateMessage: _messageController.text.trim(),
                  downloadUrl: _downloadUrlController.text.trim(),
                  isActive: _isActive,
                  createdAt: version?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (version == null) {
                    await AppVersionService.addVersion(versionData);
                  } else {
                    await AppVersionService.updateVersion(versionData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          version == null
                              ? 'Version added successfully'
                              : 'Version updated successfully',
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
        const TopBar(title: 'App Version Control', subtitle: 'Manage app versions and updates'),
        Expanded(
          child: StreamBuilder<List<AppVersionModel>>(
            stream: AppVersionService.watchAllVersions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final versions = snapshot.data ?? [];

              if (versions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.system_update, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No app versions yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Platform')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Build')),
                    DataColumn(label: Text('Force Update')),
                    DataColumn(label: Text('Active')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: versions.map((v) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                v.platform == 'android' ? Icons.android : Icons.phone_iphone,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(v.platform.toUpperCase()),
                            ],
                          ),
                        ),
                        DataCell(Text(v.version)),
                        DataCell(Text('${v.buildNumber}')),
                        DataCell(
                          v.isForceUpdate
                              ? const Icon(Icons.warning, color: Colors.orange, size: 20)
                              : const SizedBox.shrink(),
                        ),
                        DataCell(
                          v.isActive
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : const Icon(Icons.cancel, color: Colors.grey, size: 20),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showAddEditDialog(version: v),
                                tooltip: 'Edit',
                              ),
                              if (!v.isActive)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                  onPressed: () async {
                                    await AppVersionService.toggleVersionStatus(v.id, true);
                                  },
                                  tooltip: 'Set as Active',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Version'),
                                      content: Text(
                                        'Are you sure you want to delete version ${v.version}?',
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
                                    await AppVersionService.deleteVersion(v.id);
                                  }
                                },
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add App Version'),
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
