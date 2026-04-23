import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Notifications', subtitle: 'View notification history'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final alerts = snapshot.data?.docs ?? [];
              
              // Calculate notification metrics from alerts data
              int totalSent = alerts.length;
              int delivered = 0;
              int opened = 0;
              int clicked = 0;

              for (var alertDoc in alerts) {
                final data = alertDoc.data() as Map<String, dynamic>;
                // Count delivered notifications
                if (data['isDelivered'] == true) {
                  delivered++;
                }
                // Count opened notifications
                if (data['isOpened'] == true) {
                  opened++;
                }
                // Count clicked notifications
                if (data['isClicked'] == true) {
                  clicked++;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: [
                    _buildNotificationCard(
                      title: 'Total Sent',
                      icon: Icons.send,
                      color: Colors.blue,
                      value: _formatNumber(totalSent),
                      subtitle: 'Notifications sent',
                    ),
                    _buildNotificationCard(
                      title: 'Delivered',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      value: _formatNumber(delivered),
                      subtitle: 'Successfully delivered',
                    ),
                    _buildNotificationCard(
                      title: 'Opened',
                      icon: Icons.visibility,
                      color: Colors.orange,
                      value: _formatNumber(opened),
                      subtitle: 'Users opened',
                    ),
                    _buildNotificationCard(
                      title: 'Clicked',
                      icon: Icons.touch_app,
                      color: Colors.purple,
                      value: _formatNumber(clicked),
                      subtitle: 'Users clicked',
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  Widget _buildNotificationCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
