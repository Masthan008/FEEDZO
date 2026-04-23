import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'admin', 'security', 'order', 'payment', 'user'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Audit Logs', subtitle: 'View system audit logs'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('auditLogs')
                .orderBy('timestamp', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final logs = snapshot.data?.docs ?? [];
              final filteredLogs = _selectedFilter == 'all'
                  ? logs
                  : logs.where((log) {
                      final data = log.data() as Map<String, dynamic>;
                      return (data['category'] as String? ?? '').toLowerCase() == _selectedFilter;
                    }).toList();

              // Calculate stats
              final today = DateTime.now();
              final todayLogs = logs.where((log) {
                final data = log.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.year == today.year && date.month == today.month && date.day == today.day;
              }).length;

              final adminLogs = logs.where((log) {
                final data = log.data() as Map<String, dynamic>;
                return (data['category'] as String? ?? '').toLowerCase() == 'admin';
              }).length;

              final securityLogs = logs.where((log) {
                final data = log.data() as Map<String, dynamic>;
                return (data['category'] as String? ?? '').toLowerCase() == 'security';
              }).length;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard('Total Logs', logs.length.toString(), Icons.description, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Today', todayLogs.toString(), Icons.today, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Admin', adminLogs.toString(), Icons.admin_panel_settings, Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard('Security', securityLogs.toString(), Icons.security, Colors.red),
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

                    // Logs Table
                    Expanded(
                      child: filteredLogs.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No audit logs found', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Card(
                              child: ListView.separated(
                                itemCount: filteredLogs.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final log = filteredLogs[index];
                                  final data = log.data() as Map<String, dynamic>;
                                  return _buildLogItem(data);
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

  Widget _buildLogItem(Map<String, dynamic> data) {
    final action = data['action'] as String? ?? 'Unknown';
    final category = data['category'] as String? ?? 'general';
    final user = data['userName'] as String? ?? data['userId'] as String? ?? 'System';
    final details = data['details'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final ipAddress = data['ipAddress'] as String? ?? '-';

    Color categoryColor;
    IconData categoryIcon;

    switch (category.toLowerCase()) {
      case 'admin':
        categoryColor = Colors.orange;
        categoryIcon = Icons.admin_panel_settings;
        break;
      case 'security':
        categoryColor = Colors.red;
        categoryIcon = Icons.security;
        break;
      case 'order':
        categoryColor = Colors.blue;
        categoryIcon = Icons.shopping_cart;
        break;
      case 'payment':
        categoryColor = Colors.green;
        categoryIcon = Icons.payment;
        break;
      case 'user':
        categoryColor = Colors.purple;
        categoryIcon = Icons.person;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.info;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: categoryColor.withOpacity(0.2),
        child: Icon(categoryIcon, color: categoryColor, size: 20),
      ),
      title: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty) Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('By: $user • IP: $ipAddress', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
      trailing: timestamp != null
          ? Text(
              DateFormat('MMM dd, HH:mm').format(timestamp.toDate()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      onTap: () => _showLogDetails(data),
    );
  }

  void _showLogDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', data['action']?.toString() ?? 'N/A'),
              _buildDetailRow('Category', data['category']?.toString() ?? 'N/A'),
              _buildDetailRow('User', data['userName']?.toString() ?? data['userId']?.toString() ?? 'System'),
              _buildDetailRow('IP Address', data['ipAddress']?.toString() ?? 'N/A'),
              _buildDetailRow('User Agent', data['userAgent']?.toString() ?? 'N/A'),
              _buildDetailRow('Details', data['details']?.toString() ?? 'N/A'),
              _buildDetailRow('Old Value', data['oldValue']?.toString() ?? 'N/A'),
              _buildDetailRow('New Value', data['newValue']?.toString() ?? 'N/A'),
              _buildDetailRow('Timestamp', data['timestamp'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format((data['timestamp'] as Timestamp).toDate())
                  : 'N/A'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
