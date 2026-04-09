import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({super.key});

  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Driver Analytics', subtitle: 'View driver performance analytics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildAnalyticsCard(
                  title: 'Total Drivers',
                  icon: Icons.delivery_dining,
                  color: Colors.blue,
                  value: '185',
                  subtitle: 'Active drivers',
                ),
                _buildAnalyticsCard(
                  title: 'Online Now',
                  icon: Icons.circle,
                  color: Colors.green,
                  value: '42',
                  subtitle: 'Currently online',
                ),
                _buildAnalyticsCard(
                  title: 'Avg Delivery Time',
                  icon: Icons.timer,
                  color: Colors.orange,
                  value: '28 min',
                  subtitle: 'Average delivery',
                ),
                _buildAnalyticsCard(
                  title: 'Total Deliveries',
                  icon: Icons.local_shipping,
                  color: Colors.purple,
                  value: '15K',
                  subtitle: 'This month',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
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
