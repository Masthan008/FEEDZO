import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ApiLogsScreen extends StatefulWidget {
  const ApiLogsScreen({super.key});

  @override
  State<ApiLogsScreen> createState() => _ApiLogsScreenState();
}

class _ApiLogsScreenState extends State<ApiLogsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'GET', 'POST', 'PUT', 'DELETE', 'ERROR'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'API Logs', subtitle: 'View API request logs'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('apiLogs')
                .orderBy('timestamp', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final logs = snapshot.data?.docs ?? [];
              final filteredLogs = _selectedFilter == 'all'
                  ? logs
                  : _selectedFilter == 'ERROR'
                      ? logs.where((log) {
                          final data = log.data() as Map<String, dynamic>;
                          final statusCode = (data['statusCode'] as num?)?.toInt() ?? 200;
                          return statusCode >= 400;
                        }).toList()
                      : logs.where((log) {
                          final data = log.data() as Map<String, dynamic>;
                          return (data['method'] as String? ?? '').toUpperCase() == _selectedFilter;
                        }).toList();

              // Calculate stats
              final totalRequests = logs.length;
              final errorLogs = logs.where((log) {
                final data = log.data() as Map<String, dynamic>;
                final statusCode = (data['statusCode'] as num?)?.toInt() ?? 200;
                return statusCode >= 400;
              }).length;
              final successRate = totalRequests > 0 ? ((totalRequests - errorLogs) / totalRequests * 100) : 100;

              final avgResponseTime = logs.isEmpty
                  ? 0
                  : logs.fold<int>(0, (sum, log) {
                        final data = log.data() as Map<String, dynamic>;
                        return sum + ((data['responseTime'] as num?)?.toInt() ?? 0);
                      }) /
                      logs.length;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard('Total', totalRequests.toString(), Icons.api, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Success', '${successRate.toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Avg Time', '${avgResponseTime.toStringAsFixed(0)}ms', Icons.speed, Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard('Errors', errorLogs.toString(), Icons.error, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(filter),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Logs Table
                    Expanded(
                      child: filteredLogs.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.api_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No API logs found', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Card(
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 1, child: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 3, child: Text('Endpoint', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 1, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 2, child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  // Table Rows
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: filteredLogs.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final log = filteredLogs[index];
                                        final data = log.data() as Map<String, dynamic>;
                                        return _buildLogRow(data);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> data) {
    final method = (data['method'] as String? ?? 'GET').toUpperCase();
    final endpoint = data['endpoint'] as String? ?? data['path'] as String? ?? '/';
    final statusCode = (data['statusCode'] as num?)?.toInt() ?? 200;
    final responseTime = (data['responseTime'] as num?)?.toInt() ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;

    Color methodColor;
    switch (method) {
      case 'GET':
        methodColor = Colors.blue;
        break;
      case 'POST':
        methodColor = Colors.green;
        break;
      case 'PUT':
        methodColor = Colors.orange;
        break;
      case 'DELETE':
        methodColor = Colors.red;
        break;
      default:
        methodColor = Colors.grey;
    }

    Color statusColor = statusCode < 300 ? Colors.green : statusCode < 400 ? Colors.orange : Colors.red;

    return InkWell(
      onTap: () => _showLogDetails(data),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  method,
                  style: TextStyle(color: methodColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: Text(endpoint, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusCode.toString(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('${responseTime}ms', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                timestamp != null ? DateFormat('HH:mm:ss').format(timestamp.toDate()) : '-',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Method', data['method']?.toString() ?? 'N/A'),
              _buildDetailRow('Endpoint', data['endpoint']?.toString() ?? data['path']?.toString() ?? 'N/A'),
              _buildDetailRow('Status Code', data['statusCode']?.toString() ?? 'N/A'),
              _buildDetailRow('Response Time', '${data['responseTime']?.toString() ?? 'N/A'}ms'),
              _buildDetailRow('IP Address', data['ipAddress']?.toString() ?? 'N/A'),
              _buildDetailRow('User Agent', data['userAgent']?.toString() ?? 'N/A'),
              _buildDetailRow('Request ID', data['requestId']?.toString() ?? 'N/A'),
              _buildDetailRow('Timestamp', data['timestamp'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format((data['timestamp'] as Timestamp).toDate())
                  : 'N/A'),
              if (data['error'] != null) ...[
                const SizedBox(height: 8),
                const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(data['error'].toString(), style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
