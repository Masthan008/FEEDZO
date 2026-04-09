import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/social_media_model.dart';
import '../services/social_media_service.dart';
import '../widgets/topbar.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen> {
  final _platformController = TextEditingController();
  final _urlController = TextEditingController();
  final _iconController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  @override
  void dispose() {
    _platformController.dispose();
    _urlController.dispose();
    _iconController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({SocialMediaModel? socialMedia}) {
    if (socialMedia != null) {
      _platformController.text = socialMedia.platform;
      _urlController.text = socialMedia.url;
      _iconController.text = socialMedia.icon ?? '';
      _sortOrderController.text = socialMedia.sortOrder.toString();
    } else {
      _platformController.clear();
      _urlController.clear();
      _iconController.clear();
      _sortOrderController.text = '0';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(socialMedia == null ? 'Add Social Media Link' : 'Edit Social Media Link'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _platformController,
                decoration: const InputDecoration(
                  labelText: 'Platform *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Facebook, Twitter, Instagram',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., facebook, twitter, instagram',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                  border: OutlineInputBorder(),
                ),
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
              if (_platformController.text.isEmpty || _urlController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Platform and URL are required')),
                );
                return;
              }

              final socialMediaData = SocialMediaModel(
                id: socialMedia?.id ?? '',
                platform: _platformController.text.trim(),
                url: _urlController.text.trim(),
                icon: _iconController.text.trim(),
                isActive: socialMedia?.isActive ?? true,
                sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
                createdAt: socialMedia?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                if (socialMedia == null) {
                  await SocialMediaService.addSocialMedia(socialMediaData);
                } else {
                  await SocialMediaService.updateSocialMedia(socialMediaData);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        socialMedia == null
                            ? 'Social media link added successfully'
                            : 'Social media link updated successfully',
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
        const TopBar(title: 'Social Media Links', subtitle: 'Manage social media accounts'),
        Expanded(
          child: StreamBuilder<List<SocialMediaModel>>(
            stream: SocialMediaService.watchAllSocialMedia(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final socialMedia = snapshot.data ?? [];

              if (socialMedia.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No social media links yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Platform')),
                    DataColumn(label: Text('URL')),
                    DataColumn(label: Text('Sort Order')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: socialMedia.map((sm) {
                    return DataRow(
                      cells: [
                        DataCell(Text(sm.platform)),
                        DataCell(
                          Text(
                            sm.url,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DataCell(Text(sm.sortOrder.toString())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sm.isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              sm.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sm.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showAddEditDialog(socialMedia: sm),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                onPressed: () async {
                                  if (sm.sortOrder > 0) {
                                    await SocialMediaService.reorderSocialMedia(
                                      sm.id,
                                      sm.sortOrder - 1,
                                    );
                                  }
                                },
                                tooltip: 'Move Up',
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 18),
                                onPressed: () async {
                                  await SocialMediaService.reorderSocialMedia(
                                    sm.id,
                                    sm.sortOrder + 1,
                                  );
                                },
                                tooltip: 'Move Down',
                              ),
                              IconButton(
                                icon: Icon(
                                  sm.isActive ? Icons.toggle_on : Icons.toggle_off,
                                  size: 18,
                                  color: sm.isActive ? Colors.green : Colors.red,
                                ),
                                onPressed: () async {
                                  await SocialMediaService.toggleSocialMediaStatus(
                                    sm.id,
                                    !sm.isActive,
                                  );
                                },
                                tooltip: sm.isActive ? 'Deactivate' : 'Activate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Link'),
                                      content: Text(
                                        'Are you sure you want to delete "${sm.platform}"?',
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
                                    await SocialMediaService.deleteSocialMedia(sm.id);
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
              label: const Text('Add Social Media Link'),
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
