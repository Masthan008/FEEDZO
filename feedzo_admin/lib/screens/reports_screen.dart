import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Reports', subtitle: 'View and generate reports'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildReportCard(
                  title: 'Order Reports',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  description: 'View order statistics and analytics',
                ),
                _buildReportCard(
                  title: 'Transaction Reports',
                  icon: Icons.account_balance,
                  color: Colors.green,
                  description: 'View payment transactions',
                ),
                _buildReportCard(
                  title: 'Food Reports',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  description: 'View food item analytics',
                ),
                _buildReportCard(
                  title: 'Customer Wallet Reports',
                  icon: Icons.wallet,
                  color: Colors.purple,
                  description: 'View wallet transactions',
                ),
                _buildReportCard(
                  title: 'Restaurant Statistics',
                  icon: Icons.store,
                  color: Colors.red,
                  description: 'View restaurant performance',
                ),
                _buildReportCard(
                  title: 'Zone-wise Reports',
                  icon: Icons.location_city,
                  color: Colors.teal,
                  description: 'View zone-based analytics',
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
    required String description,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.assessment),
              label: const Text('View Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
