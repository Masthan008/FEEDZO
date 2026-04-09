import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DispatchManagementScreen extends StatefulWidget {
  const DispatchManagementScreen({super.key});

  @override
  State<DispatchManagementScreen> createState() => _DispatchManagementScreenState();
}

class _DispatchManagementScreenState extends State<DispatchManagementScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Dispatch Management', subtitle: 'Manage order dispatch'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('Filter by status: '),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'picked_up', child: Text('Picked Up')),
                  DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
            ],
          ),
        ),
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

              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders to dispatch', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Restaurant')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: orders.map((order) {
                    final data = order.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(Text(data['orderId'] ?? order.id)),
                        DataCell(Text(data['customerName'] ?? 'N/A')),
                        DataCell(Text(data['restaurantName'] ?? 'N/A')),
                        DataCell(_buildStatusChip(data['status'] ?? 'pending')),
                        DataCell(Text(
                          DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate()),
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 18),
                            onPressed: () {},
                            tooltip: 'View',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'assigned':
        color = Colors.blue;
        break;
      case 'picked_up':
        color = Colors.purple;
        break;
      case 'delivered':
        color = Colors.green;
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
