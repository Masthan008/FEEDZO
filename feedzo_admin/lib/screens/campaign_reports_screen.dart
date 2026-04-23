import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class CampaignReportsScreen extends StatefulWidget {
  const CampaignReportsScreen({super.key});

  @override
  State<CampaignReportsScreen> createState() => _CampaignReportsScreenState();
}

class _CampaignReportsScreenState extends State<CampaignReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Campaign Reports', subtitle: 'View marketing campaign reports'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('campaignReports').snapshots(),
            builder: (context, campaignSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
                builder: (context, promotionsSnapshot) {
                  if (campaignSnapshot.connectionState == ConnectionState.waiting ||
                      promotionsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (campaignSnapshot.hasError) {
                    return Center(child: Text('Error: ${campaignSnapshot.error}'));
                  }

                  final campaigns = promotionsSnapshot.data?.docs ?? [];
                  final analytics = campaignSnapshot.data?.docs ?? [];

                  final totalCampaigns = campaigns.where((c) {
                    final data = c.data() as Map<String, dynamic>;
                    return data['isActive'] == true;
                  }).length;

                  // Calculate totals from analytics
                  int totalImpressions = 0;
                  int totalClicks = 0;
                  int totalConversions = 0;
                  double totalRevenue = 0;

                  for (final doc in analytics) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      if (date.isAfter(_startDate) && date.isBefore(_endDate.add(const Duration(days: 1)))) {
                        totalImpressions += (data['impressions'] as num?)?.toInt() ?? 0;
                        totalClicks += (data['clicks'] as num?)?.toInt() ?? 0;
                        totalConversions += (data['conversions'] as num?)?.toInt() ?? 0;
                        totalRevenue += (data['revenue'] as num?)?.toDouble() ?? 0;
                      }
                    }
                  }

                  final ctr = totalImpressions > 0 ? (totalClicks / totalImpressions * 100) : 0;
                  final conversionRate = totalClicks > 0 ? (totalConversions / totalClicks * 100) : 0;

                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Range Selector
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Start Date'),
                                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () => _selectDate(true),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('End Date'),
                                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () => _selectDate(false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Metrics Cards
                          GridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildReportCard(
                                title: 'Active Campaigns',
                                icon: Icons.campaign,
                                color: Colors.blue,
                                value: totalCampaigns.toString(),
                                subtitle: 'Running now',
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
                              _buildReportCard(
                                title: 'CTR',
                                icon: Icons.trending_up,
                                color: Colors.teal,
                                value: '${ctr.toStringAsFixed(1)}%',
                                subtitle: 'Click-through rate',
                              ),
                              _buildReportCard(
                                title: 'Revenue',
                                icon: Icons.currency_rupee,
                                color: Colors.pink,
                                value: '₹${totalRevenue.toStringAsFixed(0)}',
                                subtitle: 'Total revenue',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Campaign List
                          const Text(
                            'Campaign Performance',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildCampaignList(campaigns, analytics),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildCampaignList(List<QueryDocumentSnapshot> campaigns, List<QueryDocumentSnapshot> analytics) {
    if (campaigns.isEmpty) {
      return const Center(
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No campaigns yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: campaigns.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          final data = campaign.data() as Map<String, dynamic>;
          final name = data['code'] ?? data['name'] ?? 'Unnamed Campaign';
          final isActive = data['isActive'] ?? false;
          
          // Calculate campaign-specific metrics
          final campaignAnalytics = analytics.where((a) {
            final aData = a.data() as Map<String, dynamic>;
            return aData['campaignId'] == campaign.id;
          });
          
          int impressions = 0;
          int clicks = 0;
          int conversions = 0;
          
          for (final a in campaignAnalytics) {
            final aData = a.data() as Map<String, dynamic>;
            impressions += (aData['impressions'] as num?)?.toInt() ?? 0;
            clicks += (aData['clicks'] as num?)?.toInt() ?? 0;
            conversions += (aData['conversions'] as num?)?.toInt() ?? 0;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.green : Colors.grey,
              child: Icon(isActive ? Icons.check : Icons.pause, color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${isActive ? 'Active' : 'Inactive'} • ${data['discountType'] ?? 'Fixed'} discount'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMetricChip(Icons.visibility, impressions.toString(), Colors.blue),
                const SizedBox(width: 8),
                _buildMetricChip(Icons.touch_app, clicks.toString(), Colors.orange),
                const SizedBox(width: 8),
                _buildMetricChip(Icons.shopping_cart, conversions.toString(), Colors.purple),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
