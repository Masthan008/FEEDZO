import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  String _filter = 'open'; // 'open', 'in_progress', 'resolved', 'all'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Support Tickets', subtitle: 'Manage customer support tickets'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('Open', 'open'),
              const SizedBox(width: 8),
              _buildFilterChip('In Progress', 'in_progress'),
              const SizedBox(width: 8),
              _buildFilterChip('Resolved', 'resolved'),
              const SizedBox(width: 8),
              _buildFilterChip('All', 'all'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filter == 'all'
                ? FirebaseFirestore.instance
                    .collection('support_tickets')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('support_tickets')
                    .where('status', isEqualTo: _filter)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final tickets = snapshot.data?.docs ?? [];

              if (tickets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No $_filter tickets',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: ListView.separated(
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = tickets[index].data() as Map<String, dynamic>;
                      final ticketId = tickets[index].id;
                      final status = data['status'] ?? 'open';
                      final priority = data['priority'] ?? 'normal';
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                      return ListTile(
                        title: Text(
                          data['subject'] ?? 'No subject',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['customerName'] ?? 'Unknown'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatusBadge(status: status),
                                const SizedBox(width: 8),
                                _PriorityBadge(priority: priority),
                                if (createdAt != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status == 'open')
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.orange),
                                onPressed: () => _updateStatus(ticketId, 'in_progress'),
                                tooltip: 'Mark in progress',
                              ),
                            if (status == 'in_progress')
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _updateStatus(ticketId, 'resolved'),
                                tooltip: 'Mark resolved',
                              ),
                            IconButton(
                              icon: const Icon(Icons.reply),
                              onPressed: () => _showReplyDialog(ticketId, data),
                              tooltip: 'Reply',
                            ),
                          ],
                        ),
                        onTap: () => _showTicketDetails(ticketId, data),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (selected) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _updateStatus(String ticketId, String status) async {
    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(ticketId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showReplyDialog(String ticketId, Map<String, dynamic> data) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject: ${data['subject'] ?? 'No subject'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['message'] ?? 'No message',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your response',
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
              if (controller.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('support_tickets')
                  .doc(ticketId)
                  .update({
                'adminResponse': controller.text.trim(),
                'respondedAt': FieldValue.serverTimestamp(),
                'status': 'in_progress',
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(String ticketId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['subject'] ?? 'No subject'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Customer', value: data['customerName'] ?? 'Unknown'),
              _DetailRow(label: 'Email', value: data['customerEmail'] ?? 'N/A'),
              _DetailRow(label: 'Status', value: data['status'] ?? 'open'),
              _DetailRow(label: 'Priority', value: data['priority'] ?? 'normal'),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(data['message'] ?? 'No message'),
              if (data['adminResponse'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Admin Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(data['adminResponse']),
                ),
              ],
            ],
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'open'
        ? Colors.blue
        : status == 'in_progress'
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'high'
        ? Colors.red
        : priority == 'medium'
            ? Colors.orange
            : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
