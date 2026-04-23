import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'pending', 'resolved', 'positive', 'negative'];

  Future<void> _markAsResolved(String feedbackId) async {
    await FirebaseFirestore.instance.collection('feedback').doc(feedbackId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback marked as resolved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteFeedback(String feedbackId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('feedback').doc(feedbackId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showRespondDialog(String feedbackId, String userId, String userName) async {
    final responseController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Respond to $userName'),
        content: TextField(
          controller: responseController,
          decoration: const InputDecoration(
            labelText: 'Your Response',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('feedback').doc(feedbackId).update({
                'response': responseController.text.trim(),
                'respondedAt': FieldValue.serverTimestamp(),
                'respondedBy': 'Admin',
                'status': 'resolved',
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response sent successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Feedback', subtitle: 'View and manage customer feedback'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final feedbackList = snapshot.data?.docs ?? [];

              // Calculate stats
              final totalFeedback = feedbackList.length;
              final pendingCount = feedbackList.where((f) {
                final data = f.data() as Map<String, dynamic>;
                return data['status'] == 'pending';
              }).length;
              final resolvedCount = feedbackList.where((f) {
                final data = f.data() as Map<String, dynamic>;
                return data['status'] == 'resolved';
              }).length;
              final positiveCount = feedbackList.where((f) {
                final data = f.data() as Map<String, dynamic>;
                return (data['rating'] as num?) != null && data['rating'] >= 4;
              }).length;

              // Apply filter
              final filteredFeedback = _selectedFilter == 'all'
                  ? feedbackList
                  : feedbackList.where((f) {
                      final data = f.data() as Map<String, dynamic>;
                      final status = data['status'] as String? ?? 'pending';
                      final rating = (data['rating'] as num?)?.toInt() ?? 0;

                      switch (_selectedFilter) {
                        case 'pending':
                          return status == 'pending';
                        case 'resolved':
                          return status == 'resolved';
                        case 'positive':
                          return rating >= 4;
                        case 'negative':
                          return rating <= 2;
                        default:
                          return true;
                      }
                    }).toList();

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard('Total', totalFeedback.toString(), Icons.feedback, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Pending', pendingCount.toString(), Icons.pending, Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard('Resolved', resolvedCount.toString(), Icons.check_circle, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Positive', positiveCount.toString(), Icons.thumb_up, Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(filter.toUpperCase()),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Feedback List
                    Expanded(
                      child: filteredFeedback.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No feedback found', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Card(
                              child: ListView.separated(
                                itemCount: filteredFeedback.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final feedback = filteredFeedback[index];
                                  final data = feedback.data() as Map<String, dynamic>;
                                  return _buildFeedbackItem(feedback.id, data);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(String id, Map<String, dynamic> data) {
    final userName = data['userName'] as String? ?? data['userId'] as String? ?? 'Anonymous';
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final comment = data['comment'] as String? ?? data['message'] as String? ?? 'No comment';
    final status = data['status'] as String? ?? 'pending';
    final type = data['type'] as String? ?? 'general';
    final timestamp = data['createdAt'] as Timestamp?;
    final response = data['response'] as String?;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rating >= 4 ? Colors.green.withOpacity(0.2) : rating <= 2 ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        child: Text(
          rating > 0 ? rating.toString() : '?',
          style: TextStyle(
            color: rating >= 4 ? Colors.green : rating <= 2 ? Colors.red : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(comment, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (response != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Response: $response',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${type.toUpperCase()} • ${timestamp != null ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate()) : 'Unknown date'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'respond':
              _showRespondDialog(id, data['userId']?.toString() ?? '', userName);
              break;
            case 'resolve':
              _markAsResolved(id);
              break;
            case 'delete':
              _deleteFeedback(id);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'respond', child: Row(children: [Icon(Icons.reply), SizedBox(width: 8), Text('Respond')])),
          if (status != 'resolved')
            const PopupMenuItem(value: 'resolve', child: Row(children: [Icon(Icons.check_circle), SizedBox(width: 8), Text('Mark Resolved')])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
        ],
      ),
    );
  }
}
