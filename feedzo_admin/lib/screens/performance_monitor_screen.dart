import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class PerformanceMonitorScreen extends StatefulWidget {
  const PerformanceMonitorScreen({super.key});

  @override
  State<PerformanceMonitorScreen> createState() => _PerformanceMonitorScreenState();
}

class _PerformanceMonitorScreenState extends State<PerformanceMonitorScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Performance Monitor', subtitle: 'View system performance metrics'),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('performanceMetrics').doc('current').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              
              // App performance metrics
              final activeUsers = (data['activeUsers'] as num?)?.toInt() ?? 0;
              final ordersPerMinute = (data['ordersPerMinute'] as num?)?.toDouble() ?? 0;
              final avgOrderValue = (data['avgOrderValue'] as num?)?.toDouble() ?? 0;
              final deliveryTime = (data['avgDeliveryTime'] as num?)?.toInt() ?? 0;
              
              // System health
              final apiLatency = (data['apiLatency'] as num?)?.toInt() ?? 0;
              final errorRate = (data['errorRate'] as num?)?.toDouble() ?? 0;
              final uptime = (data['uptime'] as num?)?.toDouble() ?? 99.9;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Performance Metrics
                    const Text(
                      'App Performance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMetricCard(
                          'Active Users',
                          activeUsers.toString(),
                          Icons.people,
                          Colors.blue,
                          'Currently online',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Orders/Min',
                          ordersPerMinute.toStringAsFixed(1),
                          Icons.shopping_bag,
                          Colors.green,
                          'Order rate',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Avg Order',
                          '₹${avgOrderValue.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          Colors.orange,
                          'Order value',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Delivery Time',
                          '${deliveryTime}min',
                          Icons.timer,
                          Colors.purple,
                          'Avg delivery',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // System Health
                    const Text(
                      'System Health',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMetricCard(
                          'API Latency',
                          '${apiLatency}ms',
                          Icons.speed,
                          apiLatency < 200 ? Colors.green : apiLatency < 500 ? Colors.orange : Colors.red,
                          'Response time',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Error Rate',
                          '${errorRate.toStringAsFixed(2)}%',
                          Icons.error_outline,
                          errorRate < 1 ? Colors.green : errorRate < 5 ? Colors.orange : Colors.red,
                          'Error percentage',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Uptime',
                          '${uptime.toStringAsFixed(1)}%',
                          Icons.cloud_done,
                          uptime > 99 ? Colors.green : Colors.orange,
                          'System availability',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          'Health Score',
                          _calculateHealthScore(apiLatency, errorRate, uptime),
                          Icons.favorite,
                          _getHealthColor(apiLatency, errorRate, uptime),
                          'Overall health',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Performance Trends
                    const Text(
                      'Performance Trends (Last 24h)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTrendCard('Orders', data['orderTrend'] as List<dynamic>? ?? []),
                    const SizedBox(height: 12),
                    _buildTrendCard('Active Users', data['userTrend'] as List<dynamic>? ?? []),
                    const SizedBox(height: 12),
                    _buildTrendCard('Revenue', data['revenueTrend'] as List<dynamic>? ?? [], isCurrency: true),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _calculateHealthScore(int latency, double errorRate, double uptime) {
    int score = 100;
    if (latency > 200) score -= 10;
    if (latency > 500) score -= 20;
    if (errorRate > 1) score -= 15;
    if (errorRate > 5) score -= 30;
    if (uptime < 99) score -= 10;
    if (uptime < 95) score -= 30;
    return '${score.clamp(0, 100)}';
  }

  Color _getHealthColor(int latency, double errorRate, double uptime) {
    final score = int.parse(_calculateHealthScore(latency, errorRate, uptime));
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  if (title == 'Health Score')
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard(String title, List<dynamic> data, {bool isCurrency = false}) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.trending_flat, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text('$title: No data available', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    // Calculate trend
    final values = data.map((e) => (e as num).toDouble()).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final first = values.first;
    final last = values.last;
    final trend = last - first;
    final trendPercent = first != 0 ? (trend / first * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              trend >= 0 ? Icons.trending_up : Icons.trending_down,
              color: trend >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${trend >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}% from yesterday',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              isCurrency ? '₹${avg.toStringAsFixed(0)}' : avg.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
