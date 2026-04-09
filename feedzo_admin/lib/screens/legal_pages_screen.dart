import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/legal_page_model.dart';
import '../services/legal_page_service.dart';
import '../widgets/topbar.dart';

class LegalPagesScreen extends StatefulWidget {
  const LegalPagesScreen({super.key});

  @override
  State<LegalPagesScreen> createState() => _LegalPagesScreenState();
}

class _LegalPagesScreenState extends State<LegalPagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Legal Pages', subtitle: 'Manage legal policy pages'),
        Expanded(
          child: StreamBuilder<List<LegalPageModel>>(
            stream: LegalPageService.watchAllLegalPages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final pages = snapshot.data ?? [];

              if (pages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No legal pages yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Slug')),
                    DataColumn(label: Text('Last Updated')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pages.map((page) {
                    return DataRow(
                      cells: [
                        DataCell(Text(page.title)),
                        DataCell(_buildTypeChip(page.type)),
                        DataCell(Text(page.slug)),
                        DataCell(Text(
                          DateFormat('MMM dd, yyyy').format(page.lastUpdated),
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () => _showPageDetails(page),
                                tooltip: 'View',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditDialog(page),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Page'),
                                      content: Text(
                                        'Are you sure you want to delete "${page.title}"?',
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
                                    await LegalPageService.deleteLegalPage(page.id);
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
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Legal Page'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'terms':
        color = Colors.blue;
        break;
      case 'privacy':
        color = Colors.green;
        break;
      case 'refund':
        color = Colors.orange;
        break;
      case 'shipping':
        color = Colors.purple;
        break;
      case 'cancellation':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showPageDetails(LegalPageModel page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(page.title),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', page.type),
                _buildDetailRow('Slug', page.slug),
                const SizedBox(height: 16),
                const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Text(page.content),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _showEditDialog();
  }

  void _showEditDialog([LegalPageModel? page]) {
    final titleController = TextEditingController(text: page?.title ?? '');
    final slugController = TextEditingController(text: page?.slug ?? '');
    final contentController = TextEditingController(text: page?.content ?? '');
    String type = page?.type ?? 'terms';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(page == null ? 'Add Legal Page' : 'Edit Legal Page'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugController,
                    decoration: const InputDecoration(
                      labelText: 'Slug *',
                      border: OutlineInputBorder(),
                      hintText: 'URL-friendly identifier (e.g., terms-of-service)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'terms', child: Text('Terms & Conditions')),
                      DropdownMenuItem(value: 'privacy', child: Text('Privacy Policy')),
                      DropdownMenuItem(value: 'refund', child: Text('Refund Policy')),
                      DropdownMenuItem(value: 'shipping', child: Text('Shipping Policy')),
                      DropdownMenuItem(value: 'cancellation', child: Text('Cancellation Policy')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 15,
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
                if (titleController.text.isEmpty || slugController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }

                final pageData = LegalPageModel(
                  id: page?.id ?? '',
                  title: titleController.text.trim(),
                  slug: slugController.text.trim().toLowerCase().replaceAll(' ', '-'),
                  content: contentController.text.trim(),
                  type: type,
                  lastUpdated: page?.lastUpdated ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (page == null) {
                    await LegalPageService.addLegalPage(pageData);
                  } else {
                    await LegalPageService.updateLegalPage(pageData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          page == null
                              ? 'Legal page added successfully'
                              : 'Legal page updated successfully',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
