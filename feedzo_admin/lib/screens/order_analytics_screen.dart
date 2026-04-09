import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class OrderAnalyticsScreen extends StatefulWidget {
  const OrderAnalyticsScreen({super.key});

  @override
  State<OrderAnalyticsScreen> createState() => _OrderAnalyticsScreenState();
}

class _OrderAnalyticsScreenState extends State<OrderAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Order Analytics', subtitle: 'View order performance analytics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildAnalyticsCard(
                  title: 'Total Orders',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  value: '45K',
                  subtitle: 'This month',
                ),
                _buildAnalyticsCard(
                  title: 'Completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: '42K',
                  subtitle: 'Successfully delivered',
                ),
                _buildAnalyticsCard(
                  title: 'Cancelled',
                  icon: Icons.cancel,
                  color: Colors.red,
                  value: '1.2K',
                  subtitle: 'Cancelled orders',
                ),
                _buildAnalyticsCard(
                  title: 'Avg Order Value',
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                  value: '₹450',
                  subtitle: 'Per order',
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
