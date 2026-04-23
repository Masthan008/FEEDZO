import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data?.docs ?? [];
              
              final now = DateTime.now();
              final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
              final totalOrders = orders.where((o) {
                final data = o.data() as Map<String, dynamic>;
                final createdAt = data['createdAt'] as Timestamp?;
                if (createdAt == null) return false;
                return createdAt.toDate().isAfter(oneMonthAgo);
              }).length;

              final completedOrders = orders.where((o) {
                final data = o.data() as Map<String, dynamic>;
                return data['status'] == 'delivered' && 
                       (data['createdAt'] as Timestamp?)?.toDate().isAfter(oneMonthAgo) == true;
              }).length;

              final cancelledOrders = orders.where((o) {
                final data = o.data() as Map<String, dynamic>;
                return data['status'] == 'cancelled' && 
                       (data['createdAt'] as Timestamp?)?.toDate().isAfter(oneMonthAgo) == true;
              }).length;

              final totalOrderValue = orders.where((o) {
                final data = o.data() as Map<String, dynamic>;
                return (data['createdAt'] as Timestamp?)?.toDate().isAfter(oneMonthAgo) == true;
              }).fold<double>(0, (sum, o) {
                final data = o.data() as Map<String, dynamic>;
                return sum + ((data['orderValue'] as num?) ?? 0).toDouble();
              });

              final avgOrderValue = totalOrders > 0 ? totalOrderValue / totalOrders : 0;

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
                          title: 'Total Orders',
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                          value: totalOrders.toString(),
                          subtitle: 'This month',
                        ),
                        _buildAnalyticsCard(
                          title: 'Completed',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          value: completedOrders.toString(),
                          subtitle: 'Successfully delivered',
                        ),
                        _buildAnalyticsCard(
                          title: 'Cancelled',
                          icon: Icons.cancel,
                          color: Colors.red,
                          value: cancelledOrders.toString(),
                          subtitle: 'Cancelled orders',
                        ),
                        _buildAnalyticsCard(
                          title: 'Avg Order Value',
                          icon: Icons.shopping_cart,
                          color: Colors.orange,
                          value: '₹${avgOrderValue.toStringAsFixed(0)}',
                          subtitle: 'Per order',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Order Trends Chart
                    _buildOrderTrendsChart(orders),
                    const SizedBox(height: 24),
                    // Revenue Chart
                    _buildRevenueChart(orders),
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

  Widget _buildOrderTrendsChart(List<QueryDocumentSnapshot> orders) {
    // Calculate orders by day for last 7 days
    final now = DateTime.now();
    final dailyOrders = List.generate(7, (index) {
      final day = now.subtract(Duration(days: index));
      final count = orders.where((o) {
        final data = o.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        final date = createdAt.toDate();
        return date.year == day.year && date.month == day.month && date.day == day.day;
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
            'Order Trends (Last 7 Days)',
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
                        final day = now.subtract(Duration(days: 6 - value.toInt()));
                        return Text('${day.day}/${day.month}', style: const TextStyle(fontSize: 10));
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
                    spots: dailyOrders.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
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

  Widget _buildRevenueChart(List<QueryDocumentSnapshot> orders) {
    // Calculate revenue by day for last 7 days
    final now = DateTime.now();
    final dailyRevenue = List.generate(7, (index) {
      final day = now.subtract(Duration(days: index));
      final revenue = orders.where((o) {
        final data = o.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        final date = createdAt.toDate();
        return date.year == day.year && date.month == day.month && date.day == day.day;
      }).fold<double>(0, (sum, o) {
        final data = o.data() as Map<String, dynamic>;
        return sum + ((data['totalAmount'] as num?) ?? 0).toDouble();
      });
      return revenue;
    }).reversed.toList();

    final maxRevenue = dailyRevenue.isNotEmpty ? dailyRevenue.reduce((a, b) => a > b ? a : b) : 1.0;

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
            'Revenue Trends (Last 7 Days)',
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
                      getTitlesWidget: (value, _) {
                        final day = now.subtract(Duration(days: 6 - value.toInt()));
                        return Text('${day.day}/${day.month}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyRevenue.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
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
