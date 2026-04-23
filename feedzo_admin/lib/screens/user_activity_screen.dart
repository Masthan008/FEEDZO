import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class UserActivityScreen extends StatefulWidget {
  const UserActivityScreen({super.key});

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'login', 'order', 'search', 'profile', 'logout'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'User Activity', subtitle: 'View user activity logs'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activityLogs')
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

              final activities = snapshot.data?.docs ?? [];
              final filteredActivities = _selectedFilter == 'all'
                  ? activities
                  : activities.where((act) {
                      final data = act.data() as Map<String, dynamic>;
                      return (data['type'] as String? ?? '').toLowerCase() == _selectedFilter;
                    }).toList();

              // Calculate stats
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final weekAgo = today.subtract(const Duration(days: 7));
              final monthAgo = today.subtract(const Duration(days: 30));

              final dailyActive = activities.where((act) {
                final data = act.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.isAfter(today);
              }).length;

              final weeklyActive = activities.where((act) {
                final data = act.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.isAfter(weekAgo);
              }).length;

              final monthlyActive = activities.where((act) {
                final data = act.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.isAfter(monthAgo);
              }).length;

              // Unique users today
              final uniqueUsersToday = <String>{};
              for (final act in activities) {
                final data = act.data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                if (ts != null && ts.toDate().isAfter(today)) {
                  uniqueUsersToday.add(data['userId']?.toString() ?? '');
                }
              }
              uniqueUsersToday.remove('');

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard('Active Now', uniqueUsersToday.length.toString(), Icons.person, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Daily', dailyActive.toString(), Icons.today, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Weekly', weeklyActive.toString(), Icons.calendar_view_week, Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard('Monthly', monthlyActive.toString(), Icons.calendar_month, Colors.purple),
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

                    // Activity List
                    Expanded(
                      child: filteredActivities.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.timeline_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No activity logs found', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Card(
                              child: ListView.separated(
                                itemCount: filteredActivities.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final activity = filteredActivities[index];
                                  final data = activity.data() as Map<String, dynamic>;
                                  return _buildActivityItem(data);
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

  Widget _buildActivityItem(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final userName = data['userName'] as String? ?? data['userId'] as String? ?? 'Unknown';
    final description = data['description'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final device = data['device'] as String? ?? 'Unknown device';

    Color typeColor;
    IconData typeIcon;

    switch (type.toLowerCase()) {
      case 'login':
        typeColor = Colors.green;
        typeIcon = Icons.login;
        break;
      case 'logout':
        typeColor = Colors.grey;
        typeIcon = Icons.logout;
        break;
      case 'order':
        typeColor = Colors.blue;
        typeIcon = Icons.shopping_cart;
        break;
      case 'search':
        typeColor = Colors.orange;
        typeIcon = Icons.search;
        break;
      case 'profile':
        typeColor = Colors.purple;
        typeIcon = Icons.person;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.circle;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: typeColor.withOpacity(0.2),
        child: Icon(typeIcon, color: typeColor, size: 20),
      ),
      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$type • $device', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
      trailing: timestamp != null
          ? Text(
              _formatTimeAgo(timestamp.toDate()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(date);
  }
}
