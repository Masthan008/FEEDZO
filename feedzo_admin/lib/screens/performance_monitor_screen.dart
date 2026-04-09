import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class PerformanceMonitorScreen extends StatefulWidget {
  const PerformanceMonitorScreen({super.key});

  @override
  State<PerformanceMonitorScreen> createState() => _PerformanceMonitorScreenState();
}

class _PerformanceMonitorScreenState extends State<PerformanceMonitorScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Performance Monitor', subtitle: 'View system performance metrics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildPerfCard(
                  title: 'CPU Usage',
                  icon: Icons.memory,
                  color: Colors.blue,
                  value: '45%',
                  subtitle: 'Current usage',
                ),
                _buildPerfCard(
                  title: 'Memory',
                  icon: Icons.storage,
                  color: Colors.green,
                  value: '62%',
                  subtitle: 'Memory usage',
                ),
                _buildPerfCard(
                  title: 'Disk Space',
                  icon: Icons.disc_full,
                  color: Colors.orange,
                  value: '78%',
                  subtitle: 'Disk usage',
                ),
                _buildPerfCard(
                  title: 'Network',
                  icon: Icons.network_check,
                  color: Colors.purple,
                  value: '125 Mbps',
                  subtitle: 'Bandwidth',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerfCard({
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
