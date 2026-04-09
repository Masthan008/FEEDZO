import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() => _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Customer Analytics', subtitle: 'View customer behavior analytics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildAnalyticsCard(
                  title: 'Total Customers',
                  icon: Icons.people,
                  color: Colors.blue,
                  value: '12,450',
                  subtitle: 'Registered users',
                ),
                _buildAnalyticsCard(
                  title: 'Active Customers',
                  icon: Icons.person_pin,
                  color: Colors.green,
                  value: '8,230',
                  subtitle: 'Active in last 30 days',
                ),
                _buildAnalyticsCard(
                  title: 'New Signups',
                  icon: Icons.person_add,
                  color: Colors.orange,
                  value: '+425',
                  subtitle: 'This month',
                ),
                _buildAnalyticsCard(
                  title: 'Retention Rate',
                  icon: Icons.sync,
                  color: Colors.purple,
                  value: '78%',
                  subtitle: '30-day retention',
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
