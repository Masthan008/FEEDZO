import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/email_template_model.dart';
import '../services/email_template_service.dart';
import '../widgets/topbar.dart';

class EmailTemplatesScreen extends StatefulWidget {
  const EmailTemplatesScreen({super.key});

  @override
  State<EmailTemplatesScreen> createState() => _EmailTemplatesScreenState();
}

class _EmailTemplatesScreenState extends State<EmailTemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Email Templates', subtitle: 'Manage email templates'),
        Expanded(
          child: StreamBuilder<List<EmailTemplateModel>>(
            stream: EmailTemplateService.watchAllTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final templates = snapshot.data ?? [];

              if (templates.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No email templates yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Event Type')),
                    DataColumn(label: Text('Target')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: templates.map((template) {
                    return DataRow(
                      cells: [
                        DataCell(Text(template.name)),
                        DataCell(Text(template.eventType)),
                        DataCell(Text(template.targetAudience)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: template.isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              template.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: template.isActive
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
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () => _showTemplateDetails(template),
                                tooltip: 'View',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditDialog(template),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(
                                  template.isActive ? Icons.toggle_on : Icons.toggle_off,
                                  size: 18,
                                  color: template.isActive ? Colors.green : Colors.red,
                                ),
                                onPressed: () async {
                                  await EmailTemplateService.toggleTemplateStatus(
                                    template.id,
                                    !template.isActive,
                                  );
                                },
                                tooltip: template.isActive ? 'Deactivate' : 'Activate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Template'),
                                      content: Text(
                                        'Are you sure you want to delete "${template.name}"?',
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
                                    await EmailTemplateService.deleteTemplate(template.id);
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
      ],
    );
  }

  void _showTemplateDetails(EmailTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Event Type', template.eventType),
                _buildDetailRow('Target Audience', template.targetAudience),
                _buildDetailRow('Subject', template.subject),
                const SizedBox(height: 16),
                const Text('Body:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(template.body, style: const TextStyle(fontSize: 12)),
                ),
                if (template.variables.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Available Variables:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...template.variables.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
                  )),
                ],
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

  void _showEditDialog(EmailTemplateModel template) {
    final subjectController = TextEditingController(text: template.subject);
    final bodyController = TextEditingController(text: template.body);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${template.name}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Available variables: {{customer_name}}, {{order_id}}, {{restaurant_name}}, {{amount}}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
              final updatedTemplate = EmailTemplateModel(
                id: template.id,
                name: template.name,
                subject: subjectController.text.trim(),
                body: bodyController.text.trim(),
                eventType: template.eventType,
                targetAudience: template.targetAudience,
                isActive: template.isActive,
                variables: template.variables,
                createdAt: template.createdAt,
                updatedAt: DateTime.now(),
              );

              try {
                await EmailTemplateService.updateTemplate(updatedTemplate);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Template updated successfully'),
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
