import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/newsletter_model.dart';
import '../services/newsletter_service.dart';
import '../widgets/topbar.dart';

class NewsletterScreen extends StatefulWidget {
  const NewsletterScreen({super.key});

  @override
  State<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _emailController.clear();
    _nameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subscriber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email is required')),
                );
                return;
              }

              final subscriber = NewsletterSubscriberModel(
                id: '',
                email: _emailController.text.trim(),
                name: _nameController.text.trim(),
                isActive: true,
                subscribedAt: DateTime.now(),
              );

              try {
                await NewsletterService.addSubscriber(subscriber);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscriber added successfully'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSendNewsletterDialog(List<NewsletterSubscriberModel> subscribers) {
    _subjectController.clear();
    _contentController.clear();

    final activeSubscribers = subscribers.where((s) => s.isActive).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Newsletter to ${activeSubscribers.length} Subscribers'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your newsletter content here...',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will send to ${activeSubscribers.length} active subscribers',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              if (_subjectController.text.isEmpty || _contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject and content are required')),
                );
                return;
              }

              try {
                await NewsletterService.sendNewsletter(
                  subject: _subjectController.text.trim(),
                  content: _contentController.text.trim(),
                  subscribers: activeSubscribers,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Newsletter sent to ${activeSubscribers.length} subscribers'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending newsletter: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Newsletter Subscriptions',
          subtitle: 'Manage email subscribers',
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final subscribers = await NewsletterService.getAllSubscribers();
                if (mounted) {
                  _showSendNewsletterDialog(subscribers);
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send Newsletter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<NewsletterSubscriberModel>>(
            stream: NewsletterService.watchAllSubscribers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final subscribers = snapshot.data ?? [];

              if (subscribers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_read, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No subscribers yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Subscribed')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: subscribers.map((sub) {
                    return DataRow(
                      cells: [
                        DataCell(Text(sub.email)),
                        DataCell(Text(sub.name ?? 'N/A')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sub.isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              sub.isActive ? 'Active' : 'Unsubscribed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sub.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          DateFormat('MMM dd, yyyy').format(sub.subscribedAt),
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Row(
                            children: [
                              if (sub.isActive)
                                IconButton(
                                  icon: const Icon(Icons.unsubscribe, size: 18),
                                  onPressed: () async {
                                    await NewsletterService.unsubscribe(sub.id);
                                  },
                                  tooltip: 'Unsubscribe',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Subscriber'),
                                      content: Text(
                                        'Are you sure you want to delete this subscriber?',
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
                                    await NewsletterService.deleteSubscriber(sub.id);
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
              label: const Text('Add Subscriber'),
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
