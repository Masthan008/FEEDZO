import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SubscriptionReportsScreen extends StatefulWidget {
  const SubscriptionReportsScreen({super.key});

  @override
  State<SubscriptionReportsScreen> createState() => _SubscriptionReportsScreenState();
}

class _SubscriptionReportsScreenState extends State<SubscriptionReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Subscription Reports', subtitle: 'View subscription order reports'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildReportCard(
                  title: 'Monthly Revenue',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  value: '₹125,000',
                  subtitle: 'This month',
                ),
                _buildReportCard(
                  title: 'Active Subscriptions',
                  icon: Icons.card_membership,
                  color: Colors.blue,
                  value: '45',
                  subtitle: 'Currently active',
                ),
                _buildReportCard(
                  title: 'New Signups',
                  icon: Icons.person_add,
                  color: Colors.orange,
                  value: '12',
                  subtitle: 'This month',
                ),
                _buildReportCard(
                  title: 'Renewals',
                  icon: Icons.refresh,
                  color: Colors.purple,
                  value: '38',
                  subtitle: 'This month',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard({
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
