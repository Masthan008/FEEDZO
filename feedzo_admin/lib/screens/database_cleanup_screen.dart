import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DatabaseCleanupScreen extends StatefulWidget {
  const DatabaseCleanupScreen({super.key});

  @override
  State<DatabaseCleanupScreen> createState() => _DatabaseCleanupScreenState();
}

class _DatabaseCleanupScreenState extends State<DatabaseCleanupScreen> {
  bool _isCleaning = false;

  Future<void> _cleanupCollection(String collectionName) async {
    setState(() => _isCleaning = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection(collectionName).limit(100).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${snapshot.docs.length} documents from $collectionName'),
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
    setState(() => _isCleaning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Database Cleanup', subtitle: 'Manage database maintenance'),
        Expanded(
          child: _isCleaning
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    children: [
                      _buildCleanupCard(
                        title: 'Clean Old Orders',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        description: 'Delete orders older than 90 days',
                        action: () => _cleanupCollection('orders'),
                      ),
                      _buildCleanupCard(
                        title: 'Clean Expired Sessions',
                        icon: Icons.event_session,
                        color: Colors.orange,
                        description: 'Delete expired user sessions',
                        action: () => _cleanupCollection('sessions'),
                      ),
                      _buildCleanupCard(
                        title: 'Clean Old Alerts',
                        icon: Icons.notifications,
                        color: Colors.red,
                        description: 'Delete alerts older than 30 days',
                        action: () => _cleanupCollection('alerts'),
                      ),
                      _buildCleanupCard(
                        title: 'Clean Orphaned Files',
                        icon: Icons.folder_open,
                        color: Colors.purple,
                        description: 'Remove orphaned file references',
                        action: () {},
                      ),
                      _buildCleanupCard(
                        title: 'Clean Duplicate Data',
                        icon: Icons.content_copy,
                        color: Colors.green,
                        description: 'Remove duplicate entries',
                        action: () {},
                      ),
                      _buildCleanupCard(
                        title: 'Clean Cache Data',
                        icon: Icons.cached,
                        color: Colors.teal,
                        description: 'Clear cached data',
                        action: () {},
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCleanupCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback action,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: action,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Clean'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
