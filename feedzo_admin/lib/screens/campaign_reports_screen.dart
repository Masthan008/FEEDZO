import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final campaigns = snapshot.data?.docs ?? [];
              final totalCampaigns = campaigns.where((c) {
                final data = c.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).length;

              // Placeholder values for impressions, clicks, conversions
              // These would need to be tracked in a separate analytics collection
              final totalImpressions = 0;
              final totalClicks = 0;
              final totalConversions = 0;

              return Padding(
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
                      value: totalCampaigns.toString(),
                      subtitle: 'Active campaigns',
                    ),
                    _buildReportCard(
                      title: 'Impressions',
                      icon: Icons.visibility,
                      color: Colors.green,
                      value: totalImpressions.toString(),
                      subtitle: 'Total views',
                    ),
                    _buildReportCard(
                      title: 'Clicks',
                      icon: Icons.touch_app,
                      color: Colors.orange,
                      value: totalClicks.toString(),
                      subtitle: 'Total clicks',
                    ),
                    _buildReportCard(
                      title: 'Conversions',
                      icon: Icons.shopping_cart,
                      color: Colors.purple,
                      value: totalConversions.toString(),
                      subtitle: 'Orders generated',
                    ),
                  ],
                ),
              );
            },
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
