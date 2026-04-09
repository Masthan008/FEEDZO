import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Audit Logs', subtitle: 'View system audit logs'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildLogCard(
                  title: 'Total Logs',
                  icon: Icons.description,
                  color: Colors.blue,
                  value: '125K',
                  subtitle: 'Total entries',
                ),
                _buildLogCard(
                  title: 'Today',
                  icon: Icons.today,
                  color: Colors.green,
                  value: '4.5K',
                  subtitle: 'Logs today',
                ),
                _buildLogCard(
                  title: 'Admin Actions',
                  icon: Icons.admin_panel_settings,
                  color: Colors.orange,
                  value: '890',
                  subtitle: 'Admin activities',
                ),
                _buildLogCard(
                  title: 'Security Events',
                  icon: Icons.security,
                  color: Colors.red,
                  value: '45',
                  subtitle: 'Security alerts',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard({
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
