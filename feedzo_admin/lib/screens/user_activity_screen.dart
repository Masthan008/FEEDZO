import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class UserActivityScreen extends StatefulWidget {
  const UserActivityScreen({super.key});

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'User Activity', subtitle: 'View user activity logs'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildActivityCard(
                  title: 'Active Users',
                  icon: Icons.person,
                  color: Colors.blue,
                  value: '8,450',
                  subtitle: 'Currently online',
                ),
                _buildActivityCard(
                  title: 'Daily Active',
                  icon: Icons.today,
                  color: Colors.green,
                  value: '12,230',
                  subtitle: 'Today',
                ),
                _buildActivityCard(
                  title: 'Weekly Active',
                  icon: Icons.calendar_view_week,
                  color: Colors.orange,
                  value: '45K',
                  subtitle: 'This week',
                ),
                _buildActivityCard(
                  title: 'Monthly Active',
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                  value: '125K',
                  subtitle: 'This month',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
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
