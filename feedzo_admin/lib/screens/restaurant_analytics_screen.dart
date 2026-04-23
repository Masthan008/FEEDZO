import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
            builder: (context, restaurantSnapshot) {
              if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (restaurantSnapshot.hasError) {
                return Center(child: Text('Error: ${restaurantSnapshot.error}'));
              }

              final restaurants = restaurantSnapshot.data?.docs ?? [];
              
              // Calculate restaurant metrics
              int totalRestaurants = restaurants.length;
              double totalRating = 0;
              int ratedRestaurants = 0;

              for (var restaurantDoc in restaurants) {
                final data = restaurantDoc.data() as Map<String, dynamic>;
                final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                if (rating > 0) {
                  totalRating += rating;
                  ratedRestaurants++;
                }
              }

              final avgRating = ratedRestaurants > 0 ? totalRating / ratedRestaurants : 0.0;

              // Now fetch orders for this month's metrics
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (orderSnapshot.hasError) {
                    return Center(child: Text('Error: ${orderSnapshot.error}'));
                  }

                  final orders = orderSnapshot.data?.docs ?? [];
                  
                  // Calculate this month's orders and revenue
                  final now = DateTime.now();
                  final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
                  
                  int totalOrders = 0;
                  double totalRevenue = 0;

                  for (var orderDoc in orders) {
                    final data = orderDoc.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    if (createdAt != null && createdAt.isAfter(oneMonthAgo)) {
                      totalOrders++;
                      totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
                    }
                  }

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
                              title: 'Total Restaurants',
                              icon: Icons.store,
                              color: Colors.blue,
                              value: totalRestaurants.toString(),
                              subtitle: 'Active restaurants',
                            ),
                            _buildAnalyticsCard(
                              title: 'Average Rating',
                              icon: Icons.star,
                              color: Colors.orange,
                              value: avgRating.toStringAsFixed(1),
                              subtitle: 'Overall rating',
                            ),
                            _buildAnalyticsCard(
                              title: 'Total Orders',
                              icon: Icons.receipt_long,
                              color: Colors.green,
                              value: _formatNumber(totalOrders),
                              subtitle: 'This month',
                            ),
                            _buildAnalyticsCard(
                              title: 'Revenue',
                              icon: Icons.attach_money,
                              color: Colors.purple,
                              value: '₹${_formatCurrency(totalRevenue)}L',
                              subtitle: 'This month',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Top Restaurants Chart
                        _buildTopRestaurantsChart(restaurants, orders),
                        const SizedBox(height: 24),
                        // Revenue Distribution
                        _buildRevenueDistributionChart(restaurants, orders),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    final inLakhs = amount / 100000;
    return inLakhs.toStringAsFixed(1);
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

  Widget _buildTopRestaurantsChart(List<QueryDocumentSnapshot> restaurants, List<QueryDocumentSnapshot> orders) {
    // Calculate top 5 restaurants by orders
    final restaurantOrders = <String, int>{};
    for (final order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final restaurantId = data['restaurantId'] as String?;
      if (restaurantId != null) {
        restaurantOrders[restaurantId] = (restaurantOrders[restaurantId] ?? 0) + 1;
      }
    }

    final topRestaurants = restaurantOrders.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topRestaurants.take(5).toList();

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
            'Top 5 Restaurants by Orders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (top5.isEmpty)
            const Center(child: Text('No order data available'))
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
                            return Text('Rest ${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
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

  Widget _buildRevenueDistributionChart(List<QueryDocumentSnapshot> restaurants, List<QueryDocumentSnapshot> orders) {
    // Calculate revenue by restaurant
    final restaurantRevenue = <String, double>{};
    for (final order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final restaurantId = data['restaurantId'] as String?;
      if (restaurantId != null) {
        restaurantRevenue[restaurantId] = (restaurantRevenue[restaurantId] ?? 0) + ((data['totalAmount'] as num?)?.toDouble() ?? 0);
      }
    }

    final topRevenue = restaurantRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topRevenue.take(5).toList();

    final maxRevenue = top5.isNotEmpty ? top5.first.value : 1.0;

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
            'Top 5 Restaurants by Revenue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (top5.isEmpty)
            const Center(child: Text('No revenue data available'))
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
                            return Text('Rest ${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
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
                          color: Colors.green,
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
