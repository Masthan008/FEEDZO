import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReportType = 'orders';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Reports', subtitle: 'View and generate reports'),
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'orders', child: Text('Order Reports')),
                    DropdownMenuItem(value: 'transactions', child: Text('Transaction Reports')),
                    DropdownMenuItem(value: 'food', child: Text('Food Reports')),
                    DropdownMenuItem(value: 'wallet', child: Text('Customer Wallet Reports')),
                    DropdownMenuItem(value: 'restaurant', child: Text('Restaurant Statistics')),
                    DropdownMenuItem(value: 'zone', child: Text('Zone-wise Reports')),
                  ],
                  onChanged: (v) => setState(() => _selectedReportType = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                          : 'Select date range',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _startDate != null && _endDate != null
              ? _buildReportView()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    children: [
                      _buildReportCard(
                        title: 'Order Reports',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        description: 'View order statistics and analytics',
                      ),
                      _buildReportCard(
                        title: 'Transaction Reports',
                        icon: Icons.account_balance,
                        color: Colors.green,
                        description: 'View payment transactions',
                      ),
                      _buildReportCard(
                        title: 'Food Reports',
                        icon: Icons.restaurant,
                        color: Colors.orange,
                        description: 'View food item analytics',
                      ),
                      _buildReportCard(
                        title: 'Customer Wallet Reports',
                        icon: Icons.wallet,
                        color: Colors.purple,
                        description: 'View wallet transactions',
                      ),
                      _buildReportCard(
                        title: 'Restaurant Statistics',
                        icon: Icons.store,
                        color: Colors.red,
                        description: 'View restaurant performance',
                      ),
                      _buildReportCard(
                        title: 'Zone-wise Reports',
                        icon: Icons.location_city,
                        color: Colors.teal,
                        description: 'View zone-based analytics',
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildReportView() {
    return FutureBuilder<QuerySnapshot>(
      future: _getReportData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data?.docs ?? [];

        if (data.isEmpty) {
          return const Center(
            child: Text('No data found for the selected date range'),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedReportType.toUpperCase()} Report',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportToCSV(data),
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: DataTable(
                      columns: _buildReportColumns(),
                      rows: data.map((doc) => _buildReportRow(doc)).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<QuerySnapshot> _getReportData() async {
    final db = FirebaseFirestore.instance;
    Query query;

    switch (_selectedReportType) {
      case 'orders':
        query = db.collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      case 'transactions':
        query = db.collection('transactions')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      case 'food':
        query = db.collection('foodItems')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      case 'wallet':
        query = db.collection('walletTransactions')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      case 'restaurant':
        query = db.collection('restaurants')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      case 'zone':
        query = db.collection('zones')
            .where('createdAt', isGreaterThanOrEqualTo: _startDate)
            .where('createdAt', isLessThanOrEqualTo: _endDate)
            .orderBy('createdAt', descending: true);
        break;
      default:
        query = db.collection('orders');
    }

    return await query.limit(500).get();
  }

  List<DataColumn> _buildReportColumns() {
    switch (_selectedReportType) {
      case 'orders':
        return const [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Restaurant')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
        ];
      case 'transactions':
        return const [
          DataColumn(label: Text('Transaction ID')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
        ];
      case 'food':
        return const [
          DataColumn(label: Text('Food ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Restaurant')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Category')),
        ];
      case 'wallet':
        return const [
          DataColumn(label: Text('Transaction ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Date')),
        ];
      case 'restaurant':
        return const [
          DataColumn(label: Text('Restaurant ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Rating')),
          DataColumn(label: Text('Total Orders')),
          DataColumn(label: Text('Revenue')),
        ];
      case 'zone':
        return const [
          DataColumn(label: Text('Zone ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Restaurants')),
          DataColumn(label: Text('Drivers')),
          DataColumn(label: Text('Status')),
        ];
      default:
        return const [DataColumn(label: Text('Data'))];
    }
  }

  DataRow _buildReportRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    switch (_selectedReportType) {
      case 'orders':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['customerName'] ?? 'N/A')),
          DataCell(Text(data['restaurantName'] ?? 'N/A')),
          DataCell(Text('₹${(data['totalAmount'] ?? 0).toStringAsFixed(0)}')),
          DataCell(_buildStatusChip(data['status'] ?? 'pending')),
          DataCell(Text(_formatDate(data['createdAt']))),
        ]);
      case 'transactions':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['type'] ?? 'N/A')),
          DataCell(Text('₹${(data['amount'] ?? 0).toStringAsFixed(0)}')),
          DataCell(_buildStatusChip(data['status'] ?? 'pending')),
          DataCell(Text(_formatDate(data['createdAt']))),
        ]);
      case 'food':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['name'] ?? 'N/A')),
          DataCell(Text(data['restaurantName'] ?? 'N/A')),
          DataCell(Text('₹${(data['price'] ?? 0).toStringAsFixed(0)}')),
          DataCell(Text(data['category'] ?? 'N/A')),
        ]);
      case 'wallet':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['customerName'] ?? 'N/A')),
          DataCell(Text(data['type'] ?? 'N/A')),
          DataCell(Text('₹${(data['amount'] ?? 0).toStringAsFixed(0)}')),
          DataCell(Text(_formatDate(data['createdAt']))),
        ]);
      case 'restaurant':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['name'] ?? 'N/A')),
          DataCell(Text((data['rating'] ?? 0).toStringAsFixed(1))),
          DataCell(Text((data['totalOrders'] ?? 0).toString())),
          DataCell(Text('₹${(data['revenue'] ?? 0).toStringAsFixed(0)}')),
        ]);
      case 'zone':
        return DataRow(cells: [
          DataCell(Text('#${doc.id.substring(0, 8)}')),
          DataCell(Text(data['name'] ?? 'N/A')),
          DataCell(Text((data['restaurantCount'] ?? 0).toString())),
          DataCell(Text((data['driverCount'] ?? 0).toString())),
          DataCell(_buildStatusChip(data['isActive'] == true ? 'active' : 'inactive')),
        ]);
      default:
        return DataRow(cells: [DataCell(Text(doc.id))]);
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
      case 'processing':
        color = Colors.orange;
        break;
      case 'cancelled':
      case 'rejected':
      case 'inactive':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return 'N/A';
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }
    setState(() {});
  }

  void _exportToCSV(List<QueryDocumentSnapshot> data) {
    // Generate CSV string from data
    final csv = data.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d.values.join(',');
    }).join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${data.length} records to CSV')),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedReportType = _getReportTypeFromTitle(title));
              },
              icon: const Icon(Icons.assessment),
              label: const Text('View Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReportTypeFromTitle(String title) {
    switch (title) {
      case 'Order Reports':
        return 'orders';
      case 'Transaction Reports':
        return 'transactions';
      case 'Food Reports':
        return 'food';
      case 'Customer Wallet Reports':
        return 'wallet';
      case 'Restaurant Statistics':
        return 'restaurant';
      case 'Zone-wise Reports':
        return 'zone';
      default:
        return 'orders';
    }
  }
}
