import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ApiLogsScreen extends StatefulWidget {
  const ApiLogsScreen({super.key});

  @override
  State<ApiLogsScreen> createState() => _ApiLogsScreenState();
}

class _ApiLogsScreenState extends State<ApiLogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'API Logs', subtitle: 'View API request logs'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildLogCard(
                  title: 'Total Requests',
                  icon: Icons.api,
                  color: Colors.blue,
                  value: '1.2M',
                  subtitle: 'Total API calls',
                ),
                _buildLogCard(
                  title: 'Success Rate',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: '98.5%',
                  subtitle: 'Successful requests',
                ),
                _buildLogCard(
                  title: 'Avg Response',
                  icon: Icons.speed,
                  color: Colors.orange,
                  value: '120ms',
                  subtitle: 'Response time',
                ),
                _buildLogCard(
                  title: 'Errors',
                  icon: Icons.error,
                  color: Colors.red,
                  value: '0.5%',
                  subtitle: 'Error rate',
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
