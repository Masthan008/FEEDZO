import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';
import '../widgets/topbar.dart';

class AIInsightsScreen extends StatelessWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Column(
      children: [
        const TopBar(title: 'AI Insights', subtitle: 'Intelligent analytics powered by platform data'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, ordersSnap) {
                  if (!usersSnap.hasData || !ordersSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = usersSnap.data!.docs;
                  final orders = ordersSnap.data!.docs;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAISummary(users, orders),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildTopRestaurants(users, orders)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildCategoryInsights(orders)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRevenueTrend(orders)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildDriverPerformance(users, orders)),
                          ],
                        ),
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

  Widget _buildAISummary(List<QueryDocumentSnapshot> users, List<QueryDocumentSnapshot> orders) {
    int totalOrders = orders.length;
    
    final Map<String, double> resRev = {};
    for (var doc in orders) {
       final d = doc.data() as Map;
       if (d['status'] == 'delivered') {
          final resName = d['restaurantName'] ?? 'Unknown';
          resRev[resName] = (resRev[resName] ?? 0) + (((d['totalAmount'] as num?) ?? 0).toDouble());
       }
    }
    String topRes = '';
    double topRev = 0;
    if (resRev.isNotEmpty) {
       final e = resRev.entries.reduce((a, b) => a.value > b.value ? a : b);
       topRes = e.key;
       topRev = e.value;
    }

    final Map<String, int> itemCounts = {};
    int totItems = 0;
    for (var doc in orders) {
       final items = (doc.data() as Map)['items'] as List?;
       if (items != null) {
          for (var item in items) {
             final name = (item as Map)['name'] ?? 'Other';
             itemCounts[name] = (itemCounts[name] ?? 0) + 1;
             totItems++;
          }
       }
    }
    String topItem = '';
    int topItemPerc = 0;
    if (itemCounts.isNotEmpty) {
       final e = itemCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
       topItem = e.key;
       topItemPerc = ((e.value / totItems) * 100).toInt();
    }

    final driverCount = users.where((u) => (u.data() as Map)['role'] == 'driver').length;

    final insights = [
      'We have processed $totalOrders total orders in recent platform history.',
      if (topRev > 0) '$topRes is your top-performing restaurant with ₹${(topRev / 1000).toStringAsFixed(1)}K generated revenue.',
      if (topItemPerc > 0) '$topItem remains the most ordered item at $topItemPerc% of all volume.',
      'We currently have $driverCount active drivers maintaining delivery times.',
      'Customer retention remains vital. Loyalty programs could increase repeat rates further.',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('AI Summary', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopRestaurants(List<QueryDocumentSnapshot> users, List<QueryDocumentSnapshot> orders) {
    final resUsers = users.where((u) => (u.data() as Map)['role'] == 'restaurant').toList();
    final List<Map<String, dynamic>> resData = [];
    
    for (var u in resUsers) {
      final name = (u.data() as Map)['name'] ?? 'Unknown';
      double rev = 0;
      int ords = 0;
      for (var doc in orders) {
         final d = doc.data() as Map;
         if (d['restaurantId'] == u.id && d['status'] == 'delivered') {
            rev += (((d['totalAmount'] as num?) ?? 0).toDouble());
            ords++;
         }
      }
      resData.add({'name': name, 'revenue': rev, 'orders': ords});
    }
    resData.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    final sorted = resData.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Top Performing Restaurants', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...sorted.asMap().entries.map((e) {
            final r = e.value;
            final rank = e.key + 1;
            final maxRev = sorted.isNotEmpty && sorted.first['revenue'] > 0 ? sorted.first['revenue'] : 1.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: rank == 1 ? AppColors.star.withValues(alpha: 0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('$rank', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? AppColors.star : AppColors.textSecondary,
                        fontSize: 13,
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: r['revenue'] / maxRev,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(rank == 1 ? AppColors.primary : AppColors.primaryLight),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${(r['revenue'] / 1000).toStringAsFixed(1)}K', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${r['orders']} orders', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryInsights(List<QueryDocumentSnapshot> orders) {
    final Map<String, int> counts = {};
    int totalItems = 0;
    for (var doc in orders) {
      final items = (doc.data() as Map)['items'] as List?;
      if (items == null) continue;
      for (var item in items) {
        final name = (item as Map)['name'] as String? ?? 'Other';
        counts[name] = (counts[name] ?? 0) + 1;
        totalItems++;
      }
    }
    
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();
    final colors = [0xFFF59E0B, 0xFF3B82F6, 0xFF10B981, 0xFFEC4899];
    
    List<Map<String, dynamic>> catData = [];
    if (top.isEmpty) {
      catData = [{'label': 'None', 'value': 100.0, 'color': 0xFF9CA3AF}];
    } else {
      for (int i = 0; i < top.length; i++) {
        catData.add({
          'label': top[i].key,
          'value': (top[i].value / totalItems) * 100,
          'color': colors[i],
        });
      }
    }

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
          const Text('Most Ordered Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: catData.map((c) => PieChartSectionData(
                  value: c['value'] as double,
                  color: Color(c['color'] as int),
                  title: '${(c['value'] as double).toInt()}%',
                  radius: 65,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...catData.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(c['color'] as int), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(c['label'] as String, style: const TextStyle(fontSize: 13))),
                Text('${(c['value'] as double).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRevenueTrend(List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    final List<double> revs = List.filled(7, 0.0);
    for (var doc in orders) {
      final data = doc.data() as Map;
      if (data['status'] != 'delivered') continue;
      final cd = data['createdAt'];
      if (cd == null) continue;
      final dt = (cd as Timestamp).toDate();
      final diff = now.difference(dt).inDays;
      if (diff >= 0 && diff < 7) {
        revs[6 - diff] += (((data['totalAmount'] as num?) ?? 0).toDouble() / 1000);
      }
    }

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
          const Text('Revenue Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Text('Trailing 7 days growth pattern', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
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
                      getTitlesWidget: (v, _) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final nowIdx = DateTime.now().weekday - 1;
                        final mappedIdx = (nowIdx - (6 - v.toInt())) % 7;
                        final actIdx = mappedIdx < 0 ? mappedIdx + 7 : mappedIdx;
                        return Text(days[actIdx], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
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
                    spots: revs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPerformance(List<QueryDocumentSnapshot> users, List<QueryDocumentSnapshot> orders) {
    final drivers = users.where((u) => (u.data() as Map)['role'] == 'driver').toList();
    final List<Map<String, dynamic>> driverData = [];
    for (var d in drivers) {
       final name = (d.data() as Map)['name'] ?? 'Driver';
       int count = orders.where((o) => (o.data() as Map)['driverId'] == d.id && (o.data() as Map)['status'] == 'delivered').length;
       driverData.add({'name': name, 'count': count});
    }
    driverData.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final sorted = driverData.take(5).toList();
    final maxD = sorted.isNotEmpty && sorted.first['count'] > 0 ? sorted.first['count'] : 1;

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
          const Text('Driver Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (sorted.isEmpty) const Text('No drivers', style: TextStyle(color: AppColors.textSecondary)),
          ...sorted.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(d['name'][0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: d['count'] / maxD,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('${d['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
