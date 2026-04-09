import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/driver_earnings_model.dart';
import '../services/driver_earnings_service.dart';
import '../widgets/topbar.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Driver Earnings', subtitle: 'View driver earnings and payouts'),
        Expanded(
          child: StreamBuilder<List<DriverEarningsModel>>(
            stream: DriverEarningsService.watchAllEarnings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final earnings = snapshot.data ?? [];

              if (earnings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payments, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No earnings recorded yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Driver')),
                    DataColumn(label: Text('Period')),
                    DataColumn(label: Text('Deliveries')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Net')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: earnings.map((e) {
                    return DataRow(
                      cells: [
                        DataCell(Text(e.driverName)),
                        DataCell(Text(
                          '${DateFormat('MMM dd').format(e.periodStart)} - ${DateFormat('MMM dd').format(e.periodEnd)}',
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(Text('${e.totalDeliveries}')),
                        DataCell(Text(
                          '₹${e.totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        DataCell(Text(
                          '₹${e.netEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Earnings'),
                                  content: Text('Delete earnings record for ${e.driverName}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await DriverEarningsService.deleteEarnings(e.id);
                              }
                            },
                            tooltip: 'Delete',
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
}
