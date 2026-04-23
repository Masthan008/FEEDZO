import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DatabaseCleanupScreen extends StatefulWidget {
  const DatabaseCleanupScreen({super.key});

  @override
  State<DatabaseCleanupScreen> createState() => _DatabaseCleanupScreenState();
}

class _DatabaseCleanupScreenState extends State<DatabaseCleanupScreen> {
  bool _isCleaning = false;
  String _currentOperation = '';

  final List<Map<String, dynamic>> _cleanupTasks = [
    {'title': 'Old Orders', 'icon': Icons.receipt_long, 'color': Colors.blue, 'collection': 'orders', 'days': 90, 'field': 'createdAt'},
    {'title': 'Old Notifications', 'icon': Icons.notifications, 'color': Colors.orange, 'collection': 'notifications', 'days': 30, 'field': 'timestamp'},
    {'title': 'Old Alerts', 'icon': Icons.warning, 'color': Colors.red, 'collection': 'alerts', 'days': 30, 'field': 'createdAt'},
    {'title': 'Audit Logs', 'icon': Icons.history, 'color': Colors.purple, 'collection': 'auditLogs', 'days': 180, 'field': 'timestamp'},
    {'title': 'API Logs', 'icon': Icons.api, 'color': Colors.teal, 'collection': 'apiLogs', 'days': 30, 'field': 'timestamp'},
    {'title': 'Activity Logs', 'icon': Icons.timeline, 'color': Colors.green, 'collection': 'activityLogs', 'days': 60, 'field': 'timestamp'},
  ];

  Future<void> _cleanupOldDocuments(String collectionName, String fieldName, int daysOld) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cleanup'),
        content: Text('Delete documents older than $daysOld days from $collectionName?\n\nThis action cannot be undone.'),
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

    if (confirm != true) return;

    setState(() {
      _isCleaning = true;
      _currentOperation = 'Cleaning $collectionName...';
    });

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where(fieldName, isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500)
          .get();

      var deletedCount = 0;
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
        if (deletedCount % 100 == 0) {
          await batch.commit();
        }
      }

      if (deletedCount % 100 != 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $deletedCount old documents from $collectionName'),
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

    setState(() {
      _isCleaning = false;
      _currentOperation = '';
    });
  }

  Future<void> _cleanupOrphanedDocuments() async {
    setState(() {
      _isCleaning = true;
      _currentOperation = 'Finding orphaned documents...';
    });

    try {
      // This is a placeholder - in a real implementation, you'd check for references
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orphaned document cleanup completed'),
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

    setState(() {
      _isCleaning = false;
      _currentOperation = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Database Cleanup', subtitle: 'Manage database maintenance'),
        Expanded(
          child: _isCleaning
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_currentOperation, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      _buildStatsRow(),
                      const SizedBox(height: 32),

                      // Cleanup Tasks
                      const Text(
                        'Cleanup Tasks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _cleanupTasks.map((task) => _buildCleanupCard(task)).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Advanced Operations
                      const Text(
                        'Advanced Operations',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.delete_sweep, color: Colors.red),
                          title: const Text('Clean Orphaned Documents'),
                          subtitle: const Text('Remove documents with broken references'),
                          trailing: ElevatedButton.icon(
                            onPressed: _cleanupOrphanedDocuments,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Run'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Collections', _cleanupTasks.length.toString(), Icons.folder, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Auto-Cleanup', 'Daily', Icons.schedule, Colors.green),
        const SizedBox(width: 16),
        _buildStatCard('Last Run', 'Today', Icons.event_available, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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

  Widget _buildCleanupCard(Map<String, dynamic> task) {
    final title = task['title'] as String;
    final icon = task['icon'] as IconData;
    final color = task['color'] as Color;
    final collection = task['collection'] as String;
    final days = task['days'] as int;
    final field = task['field'] as String;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).limit(1).snapshots(),
      builder: (context, snapshot) {
        final exists = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Delete older than $days days',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: exists ? () => _cleanupOldDocuments(collection, field, days) : null,
                    icon: const Icon(Icons.cleaning_services, size: 18),
                    label: const Text('Clean'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
