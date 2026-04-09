import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class CampaignReportsScreen extends StatefulWidget {
  const CampaignReportsScreen({super.key});

  @override
  State<CampaignReportsScreen> createState() => _CampaignReportsScreenState();
}

class _CampaignReportsScreenState extends State<CampaignReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Campaign Reports', subtitle: 'View marketing campaign reports'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              children: [
                _buildReportCard(
                  title: 'Total Campaigns',
                  icon: Icons.campaign,
                  color: Colors.blue,
                  value: '15',
                  subtitle: 'Active campaigns',
                ),
                _buildReportCard(
                  title: 'Impressions',
                  icon: Icons.visibility,
                  color: Colors.green,
                  value: '125K',
                  subtitle: 'Total views',
                ),
                _buildReportCard(
                  title: 'Clicks',
                  icon: Icons.touch_app,
                  color: Colors.orange,
                  value: '8,450',
                  subtitle: 'Total clicks',
                ),
                _buildReportCard(
                  title: 'Conversions',
                  icon: Icons.shopping_cart,
                  color: Colors.purple,
                  value: '425',
                  subtitle: 'Orders generated',
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
