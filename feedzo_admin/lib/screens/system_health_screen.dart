import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'System Health', subtitle: 'View system health metrics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildHealthCard(
                  title: 'Server Status',
                  icon: Icons.dns,
                  color: Colors.green,
                  value: 'Online',
                  subtitle: 'All systems operational',
                ),
                _buildHealthCard(
                  title: 'Database',
                  icon: Icons.storage,
                  color: Colors.green,
                  value: 'Healthy',
                  subtitle: 'Response time: 45ms',
                ),
                _buildHealthCard(
                  title: 'API Rate',
                  icon: Icons.speed,
                  color: Colors.blue,
                  value: '98%',
                  subtitle: 'Success rate',
                ),
                _buildHealthCard(
                  title: 'Uptime',
                  icon: Icons.access_time,
                  color: Colors.orange,
                  value: '99.9%',
                  subtitle: 'Last 30 days',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard({
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
