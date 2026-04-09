import 'package:flutter/material.dart';
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
          child: Padding(
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
                  value: '125K',
                  subtitle: 'Notifications sent',
                ),
                _buildNotificationCard(
                  title: 'Delivered',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: '118K',
                  subtitle: 'Successfully delivered',
                ),
                _buildNotificationCard(
                  title: 'Opened',
                  icon: Icons.visibility,
                  color: Colors.orange,
                  value: '45K',
                  subtitle: 'Users opened',
                ),
                _buildNotificationCard(
                  title: 'Clicked',
                  icon: Icons.touch_app,
                  color: Colors.purple,
                  value: '12K',
                  subtitle: 'Users clicked',
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
