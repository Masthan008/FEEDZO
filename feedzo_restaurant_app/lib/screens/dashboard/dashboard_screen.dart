import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../data/mock_data.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hello, ${auth.userName} ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text('👋', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auth.restaurantName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Online/Offline Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppShape.round,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: auth.isRestaurantOpen
                                    ? const Color(0xFF4ADE80)
                                    : Colors.red.shade300,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: auth.isRestaurantOpen
                                        ? const Color(0xFF4ADE80)
                                            .withValues(alpha: 0.6)
                                        : Colors.red.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.isRestaurantOpen ? 'OPEN' : 'CLOSED',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: auth.isRestaurantOpen,
                                onChanged: (v) =>
                                    auth.toggleRestaurantStatus(v),
                                activeColor: Colors.white,
                                activeTrackColor:
                                    Colors.white.withValues(alpha: 0.3),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick Stats Row
                  Row(
                    children: [
                      _QuickStat(
                        label: 'Active',
                        value: '${orders.activeOrders.length}',
                        icon: Icons.local_fire_department_rounded,
                      ),
                      const SizedBox(width: 12),
                      _QuickStat(
                        label: 'New',
                        value: '${orders.pendingOrders.length}',
                        icon: Icons.notifications_active_rounded,
                      ),
                      const SizedBox(width: 12),
                      _QuickStat(
                        label: 'Revenue',
                        value: '₹${(orders.totalRevenue / 1000).toStringAsFixed(1)}K',
                        icon: Icons.trending_up_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        title: 'Total Orders',
                        value: '${orders.totalOrders}',
                        icon: Icons.receipt_long_rounded,
                        subtitle: 'Lifetime',
                      ),
                      StatCard(
                        title: 'Revenue',
                        value: '₹${orders.totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee_rounded,
                        iconColor: AppColors.info,
                        subtitle: 'Total Earnings',
                      ),
                      StatCard(
                        title: 'Avg. Prep Time',
                        value:
                            '${orders.averagePrepTime.toStringAsFixed(0)} min',
                        icon: Icons.timer_rounded,
                        iconColor: Colors.orange,
                        subtitle: 'Per Order',
                      ),
                      StatCard(
                        title: 'New Orders',
                        value: '${orders.pendingOrders.length}',
                        icon: Icons.pending_actions_rounded,
                        iconColor: AppColors.warning,
                        subtitle: 'Waiting Action',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Weekly Performance ──
                  const Text(
                    'Weekly Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppShape.large,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (orders.weeklyPerformance.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) *
                                      1.2)
                                  .clamp(100, double.infinity),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              getTooltipItem: (group, gi, rod, ri) {
                                return BarTooltipItem(
                                  '₹${rod.toY.toStringAsFixed(0)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  if (v.toInt() < 0 ||
                                      v.toInt() >= MockData.weekDays.length)
                                    return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      MockData.weekDays[v.toInt()],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            7,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: orders.weeklyPerformance[i],
                                  gradient: i == DateTime.now().weekday - 1
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryLight,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        )
                                      : null,
                                  color: i != DateTime.now().weekday - 1
                                      ? AppColors.primaryLight
                                          .withValues(alpha: 0.3)
                                      : null,
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Top Items ──
                  const Text(
                    'Top Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppShape.large,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: orders.topItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu_outlined,
                                    size: 40,
                                    color: AppColors.textMuted,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No orders delivered yet.',
                                    style:
                                        TextStyle(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: orders.topItems.entries
                                .take(5)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final rank = entry.key + 1;
                                  final item = entry.value;
                                  final maxVal =
                                      orders.topItems.values.first.toDouble();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            gradient: rank == 1
                                                ? const LinearGradient(
                                                    colors: [
                                                      AppColors.primary,
                                                      AppColors.primaryLight,
                                                    ],
                                                  )
                                                : null,
                                            color: rank != 1
                                                ? AppColors.surfaceVariant
                                                : null,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$rank',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: rank == 1
                                                    ? Colors.white
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.key,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    AppShape.round,
                                                child:
                                                    LinearProgressIndicator(
                                                  value:
                                                      item.value / maxVal,
                                                  backgroundColor: AppColors
                                                      .border
                                                      .withValues(alpha: 0.5),
                                                  color: rank == 1
                                                      ? AppColors.primary
                                                      : AppColors.primaryLight
                                                          .withValues(
                                                              alpha: 0.6),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${item.value} sold',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: AppShape.medium,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
