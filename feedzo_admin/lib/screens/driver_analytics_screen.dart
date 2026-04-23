import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({super.key});

  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Driver Analytics', subtitle: 'View driver performance analytics'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
            builder: (context, driversSnapshot) {
              if (driversSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (driversSnapshot.hasError) {
                return Center(child: Text('Error: ${driversSnapshot.error}'));
              }

              final drivers = driversSnapshot.data?.docs ?? [];
              final totalDrivers = drivers.length;
              final onlineDrivers = drivers.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isOnline'] == true;
              }).length;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('status', isEqualTo: 'delivered')
                    .snapshots(),
                builder: (context, ordersSnapshot) {
                  if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ordersSnapshot.hasError) {
                    return Center(child: Text('Error: ${ordersSnapshot.error}'));
                  }

                  final orders = ordersSnapshot.data?.docs ?? [];
                  
                  final now = DateTime.now();
                  final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
                  final totalDeliveries = orders.where((o) {
                    final data = o.data() as Map<String, dynamic>;
                    final deliveredAt = data['deliveredAt'] as Timestamp?;
                    if (deliveredAt == null) return false;
                    return deliveredAt.toDate().isAfter(oneMonthAgo);
                  }).length;

                  // Calculate avg delivery time from order timestamps
                  int totalDeliveryTimeMinutes = 0;
                  int deliveryCount = 0;

                  for (var orderDoc in orders) {
                    final data = orderDoc.data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] as Timestamp?;
                    final deliveredAt = data['deliveredAt'] as Timestamp?;
                    
                    if (createdAt != null && deliveredAt != null) {
                      final duration = deliveredAt.toDate().difference(createdAt.toDate());
                      totalDeliveryTimeMinutes += duration.inMinutes;
                      deliveryCount++;
                    }
                  }

                  final avgDeliveryTime = deliveryCount > 0 
                      ? (totalDeliveryTimeMinutes / deliveryCount).round() 
                      : 0;

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
                              title: 'Total Drivers',
                              icon: Icons.delivery_dining,
                              color: Colors.blue,
                              value: totalDrivers.toString(),
                              subtitle: 'Active drivers',
                            ),
                            _buildAnalyticsCard(
                              title: 'Online Now',
                              icon: Icons.circle,
                              color: Colors.green,
                              value: onlineDrivers.toString(),
                              subtitle: 'Currently online',
                            ),
                            _buildAnalyticsCard(
                              title: 'Avg Delivery Time',
                              icon: Icons.timer,
                              color: Colors.orange,
                              value: '$avgDeliveryTime min',
                              subtitle: 'Average delivery',
                            ),
                            _buildAnalyticsCard(
                              title: 'Total Deliveries',
                              icon: Icons.local_shipping,
                              color: Colors.purple,
                              value: totalDeliveries.toString(),
                              subtitle: 'This month',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Delivery Trends Chart
                        _buildDeliveryTrendsChart(orders),
                        const SizedBox(height: 24),
                        // Driver Performance
                        _buildDriverPerformanceChart(drivers, orders),
                      ],
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

  Widget _buildDeliveryTrendsChart(List<QueryDocumentSnapshot> orders) {
    // Calculate deliveries by day for last 7 days
    final now = DateTime.now();
    final dailyDeliveries = List.generate(7, (index) {
      final day = now.subtract(Duration(days: index));
      final count = orders.where((o) {
        final data = o.data() as Map<String, dynamic>;
        final deliveredAt = data['deliveredAt'] as Timestamp?;
        if (deliveredAt == null) return false;
        final date = deliveredAt.toDate();
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
            'Delivery Trends (Last 7 Days)',
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
                    spots: dailyDeliveries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
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

  Widget _buildDriverPerformanceChart(List<QueryDocumentSnapshot> drivers, List<QueryDocumentSnapshot> orders) {
    // Calculate top 5 drivers by deliveries
    final driverDeliveries = <String, int>{};
    for (final order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final driverId = data['driverId'] as String?;
      if (driverId != null) {
        driverDeliveries[driverId] = (driverDeliveries[driverId] ?? 0) + 1;
      }
    }

    final topDrivers = driverDeliveries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topDrivers.take(5).toList();

    final maxDeliveries = top5.isNotEmpty ? top5.first.value.toDouble() : 1.0;

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
            'Top 5 Drivers (This Month)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (top5.isEmpty)
            const Center(child: Text('No delivery data available'))
          else
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
                          if (value.toInt() < top5.length) {
                            return Text('Driver ${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: top5.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value.value as num).toDouble(),
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
