import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (usersSnapshot.hasError) {
                return Center(child: Text('Error: ${usersSnapshot.error}'));
              }

              final users = usersSnapshot.data?.docs ?? [];
              final totalCustomers = users.length;
              
              final now = DateTime.now();
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              final activeCustomers = users.where((u) {
                final data = u.data() as Map<String, dynamic>;
                final lastActive = data['lastActiveAt'] as Timestamp?;
                if (lastActive == null) return false;
                return lastActive.toDate().isAfter(thirtyDaysAgo);
              }).length;

              final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
              final newSignups = users.where((u) {
                final data = u.data() as Map<String, dynamic>;
                final createdAt = data['createdAt'] as Timestamp?;
                if (createdAt == null) return false;
                return createdAt.toDate().isAfter(oneMonthAgo);
              }).length;

              // Calculate retention rate (simplified)
              final retentionRate = totalCustomers > 0 
                  ? ((activeCustomers / totalCustomers) * 100).toStringAsFixed(0) 
                  : '0';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                    _buildAnalyticsCard(
                      title: 'Total Customers',
                      icon: Icons.people,
                      color: Colors.blue,
                      value: totalCustomers.toString(),
                      subtitle: 'Registered users',
                    ),
                    _buildAnalyticsCard(
                      title: 'Active Customers',
                      icon: Icons.person_pin,
                      color: Colors.green,
                      value: activeCustomers.toString(),
                      subtitle: 'Active in last 30 days',
                    ),
                    _buildAnalyticsCard(
                      title: 'New Signups',
                      icon: Icons.person_add,
                      color: Colors.orange,
                      value: '+$newSignups',
                      subtitle: 'This month',
                    ),
                    _buildAnalyticsCard(
                      title: 'Retention Rate',
                      icon: Icons.sync,
                      color: Colors.purple,
                      value: '$retentionRate%',
                      subtitle: '30-day retention',
                    ),
                  ],
                ),
                    const SizedBox(height: 24),
                    // Customer Growth Chart
                    _buildCustomerGrowthChart(users),
                    const SizedBox(height: 24),
                    // Signup Trends
                    _buildSignupTrends(users),
                  ],
                ),
              );
            },
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

  Widget _buildCustomerGrowthChart(List<QueryDocumentSnapshot> users) {
    // Calculate customer signups by month for last 6 months
    final now = DateTime.now();
    final monthlySignups = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - index, 1);
      final count = users.where((u) {
        final data = u.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        final date = createdAt.toDate();
        return date.year == month.year && date.month == month.month;
      }).length;
      return count;
    }).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Growth (Last 6 Months)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        final now = DateTime.now();
                        final monthIndex = (now.month - 6 + value.toInt() + 12) % 12;
                        return Text(months[monthIndex], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlySignups.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupTrends(List<QueryDocumentSnapshot> users) {
    // Calculate signup distribution by day of week
    final dayCounts = List.filled(7, 0);
    for (final user in users) {
      final data = user.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt != null) {
        dayCounts[createdAt.toDate().weekday % 7]++;
      }
    }

    final maxCount = dayCounts.reduce((a, b) => a > b ? a : b);
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signup Trends by Day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text(days[value.toInt()], style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dayCounts.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: maxCount > 0 ? (e.value / maxCount) * 100 : 0,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
