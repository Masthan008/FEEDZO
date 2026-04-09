import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/tip_model.dart';
import '../services/tip_service.dart';
import '../widgets/topbar.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Tips System', subtitle: 'View customer tips to drivers'),
        Expanded(
          child: StreamBuilder<List<TipModel>>(
            stream: TipService.watchAllTips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final tips = snapshot.data ?? [];

              if (tips.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No tips recorded yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Driver ID')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Method')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: tips.map((tip) {
                    return DataRow(
                      cells: [
                        DataCell(Text(tip.customerName)),
                        DataCell(Text(tip.driverId)),
                        DataCell(
                          Text(
                            '₹${tip.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DataCell(Text(tip.paymentMethod ?? 'N/A')),
                        DataCell(Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(tip.createdAt),
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Tip'),
                                  content: Text('Delete tip of ₹${tip.amount}?'),
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
                                await TipService.deleteTip(tip.id);
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
