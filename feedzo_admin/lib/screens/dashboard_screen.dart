import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../data/models.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/topbar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Column(
      children: [
        const TopBar(title: 'Dashboard', subtitle: 'Welcome back, Super Admin'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, ordersSnap) {
                  final users = usersSnap.data?.docs ?? [];
                  final orders = ordersSnap.data?.docs ?? [];
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatGrid(users, orders),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildOrdersChart(orders)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildCategoryPie(orders)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildRevenueChart(orders)),
                            const SizedBox(width: 20),
                            Expanded(flex: 3, child: _buildRecentOrders(orders)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildLiveActivityFeed(ap)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildDelayedOrders(ap)),
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

  Widget _buildStatGrid(List<QueryDocumentSnapshot> users, List<QueryDocumentSnapshot> orders) {
    final userCount = users.length;
    final restaurantCount = users.where((d) => (d.data() as Map)['role'] == 'restaurant').length;
    final driverCount = users.where((d) => (d.data() as Map)['role'] == 'driver').length;
    final orderCount = orders.length;
    final pendingCount = orders.where((d) => (d.data() as Map)['status'] == 'placed').length;
    final revenue = orders.where((d) => (d.data() as Map)['status'] == 'delivered')
        .fold<double>(0, (s, d) => s + (((d.data() as Map)['totalAmount'] as num?) ?? 0).toDouble());

            final cards = [
              StatCard(
                title: 'Total Users',
                value: '$userCount',
                icon: Icons.people_rounded,
                color: AppColors.info,
                subtitle: 'Registered users',
              ),
              StatCard(
                title: 'Restaurants',
                value: '$restaurantCount',
                icon: Icons.store_rounded,
                color: AppColors.primary,
                subtitle: 'Partner restaurants',
              ),
              StatCard(
                title: 'Drivers',
                value: '$driverCount',
                icon: Icons.delivery_dining_rounded,
                color: const Color(0xFF7C3AED),
                subtitle: 'Registered drivers',
              ),
              StatCard(
                title: 'Total Orders',
                value: '$orderCount',
                icon: Icons.receipt_long_rounded,
                color: AppColors.warning,
                subtitle: '$pendingCount pending',
              ),
              StatCard(
                title: 'Revenue',
                value: 'Rs.${(revenue / 1000).toStringAsFixed(1)}K',
                icon: Icons.currency_rupee_rounded,
                color: AppColors.primary,
                subtitle: 'From delivered orders',
              ),
            ];
            return LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 900 ? 5 : constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 900 ? 1.7 : 1.5,
                  children: cards,
                );
              },
            );
  }

  Widget _buildOrdersChart(List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    final List<int> counts = List.filled(7, 0);
    for (var doc in orders) {
      final cd = (doc.data() as Map)['createdAt'];
      if (cd == null) continue;
      final dt = (cd as Timestamp).toDate();
      final diff = now.difference(dt).inDays;
      if (diff >= 0 && diff < 7) {
        // Map 0 to index 6 (today), diff 6 to index 0.
        counts[6 - diff]++;
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
          const Text(
            'Orders Over Time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Last 7 days',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[v.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: counts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF7C3AED)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
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
    double maxR = revs.isEmpty ? 20 : revs.reduce((a, b) => a > b ? a : b);
    if (maxR < 20) maxR = 20;
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
            'Revenue Growth',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            '₹ in thousands',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxR * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        // Calculate actual day matching the bar index
                        final nowIdx = DateTime.now().weekday - 1;
                        final mappedIdx = (nowIdx - (6 - v.toInt())) % 7;
                        final actIdx = mappedIdx < 0 ? mappedIdx + 7 : mappedIdx;
                        return Text(
                          days[actIdx],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: revs
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 24,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxR * 1.2,
                              color: AppColors.surfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPie(List<QueryDocumentSnapshot> orders) {
    final Map<String, int> counts = {};
    int totalItems = 0;
    for (var doc in orders) {
      final items = (doc.data() as Map)['items'] as List?;
      if (items == null) continue;
      for (var item in items) {
        final name = (item as Map)['name'] as String? ?? 'Other'; // No category saved in order directly, grouping by item name
        counts[name] = (counts[name] ?? 0) + 1;
        totalItems++;
      }
    }
    
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();
    final colors = [0xFFF59E0B, 0xFF3B82F6, 0xFF10B981, 0xFFEC4899, 0xFF8B5CF6];
    
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
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'By order volume',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: catData
                    .map(
                      (c) => PieChartSectionData(
                        value: c['value'] as double,
                        color: Color(c['color'] as int),
                        title: '${(c['value'] as double).toInt()}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...catData.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(c['color'] as int),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${c['value'].toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<QueryDocumentSnapshot> orders) {
    final sorted = List.from(orders)..sort((a, b) {
      final t1 = (a.data() as Map)['createdAt'] as Timestamp?;
      final t2 = (b.data() as Map)['createdAt'] as Timestamp?;
      return (t2?.seconds ?? 0).compareTo(t1?.seconds ?? 0);
    });
    final recent = sorted.take(5).toList();
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
            child: Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...recent.map((o) => _OrderRow(order: o.data() as Map, id: o.id)),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Map order;
  final String id;
  const _OrderRow({required this.order, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '#${id.substring(0, 5)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              order['customerName'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              order['restaurantName'] ?? 'Unknown',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹${(((order['totalAmount'] as num?) ?? 0).toDouble()).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

Widget _buildLiveActivityFeed(AdminProvider ap) {
  IconData getIcon(ActivityType t) {
    switch (t) {
      case ActivityType.orderPlaced:
        return Icons.add_shopping_cart_rounded;
      case ActivityType.driverAssigned:
        return Icons.delivery_dining_rounded;
      case ActivityType.orderDelivered:
        return Icons.check_circle_rounded;
      case ActivityType.orderDelayed:
        return Icons.warning_rounded;
      case ActivityType.paymentReleased:
        return Icons.payments_rounded;
      case ActivityType.cashSubmitted:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color getColor(ActivityType t) {
    switch (t) {
      case ActivityType.orderPlaced:
        return AppColors.primary;
      case ActivityType.driverAssigned:
        return AppColors.info;
      case ActivityType.orderDelivered:
        return AppColors.statusDelivered;
      case ActivityType.orderDelayed:
        return AppColors.error;
      case ActivityType.paymentReleased:
        return const Color(0xFF7C3AED);
      case ActivityType.cashSubmitted:
        return const Color(0xFF0891B2);
      default:
        return AppColors.textSecondary;
    }
  }

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
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Live Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        SizedBox(
          height: 380,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ap.activityFeed.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border, indent: 60),
            itemBuilder: (context, index) {
              final act = ap.activityFeed[index];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getColor(act.type).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIcon(act.type),
                    color: getColor(act.type),
                    size: 16,
                  ),
                ),
                title: Text(
                  act.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _timeAgo(act.time),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildDelayedOrders(AdminProvider ap) {
  final delayed = ap.delayedOrders;
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delayed Orders',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${delayed.length}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        if (delayed.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No delayed orders',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...delayed.map(
            (o) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${o.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${DateTime.now().difference(o.placedAt).inMinutes}m ago',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    o.customerName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    o.restaurantName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
