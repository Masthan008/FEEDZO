import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class RestaurantAnalyticsScreen extends StatefulWidget {
  const RestaurantAnalyticsScreen({super.key});

  @override
  State<RestaurantAnalyticsScreen> createState() => _RestaurantAnalyticsScreenState();
}

class _RestaurantAnalyticsScreenState extends State<RestaurantAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Restaurant Analytics', subtitle: 'View restaurant performance analytics'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildAnalyticsCard(
                  title: 'Total Restaurants',
                  icon: Icons.store,
                  color: Colors.blue,
                  value: '245',
                  subtitle: 'Active restaurants',
                ),
                _buildAnalyticsCard(
                  title: 'Average Rating',
                  icon: Icons.star,
                  color: Colors.orange,
                  value: '4.2',
                  subtitle: 'Overall rating',
                ),
                _buildAnalyticsCard(
                  title: 'Total Orders',
                  icon: Icons.receipt_long,
                  color: Colors.green,
                  value: '45K',
                  subtitle: 'This month',
                ),
                _buildAnalyticsCard(
                  title: 'Revenue',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                  value: '₹12.5L',
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
