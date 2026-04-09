import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/cash_limit_model.dart';
import '../services/cash_limit_service.dart';
import '../widgets/topbar.dart';

class CashLimitScreen extends StatefulWidget {
  const CashLimitScreen({super.key});

  @override
  State<CashLimitScreen> createState() => _CashLimitScreenState();
}

class _CashLimitScreenState extends State<CashLimitScreen> {
  final _maxCashController = TextEditingController();

  void _showSetLimitDialog(CashLimitModel limit) {
    _maxCashController.text = limit.maxCashInHand.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Cash Limit for ${limit.driverName}'),
        content: TextField(
          controller: _maxCashController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Maximum Cash in Hand (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
            final maxCash = double.tryParse(_maxCashController.text) ?? 0;
            if (maxCash <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }
            final updatedLimit = CashLimitModel(
              id: limit.id,
              driverId: limit.driverId,
              driverName: limit.driverName,
              maxCashInHand: maxCash,
              currentCash: limit.currentCash,
              updatedAt: DateTime.now(),
            );
            await CashLimitService.updateLimit(updatedLimit);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cash limit updated'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Maximum Cash in Hand', subtitle: 'Manage driver cash limits'),
        Expanded(
          child: StreamBuilder<List<CashLimitModel>>(
            stream: CashLimitService.watchAllLimits(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final limits = snapshot.data ?? [];

              if (limits.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No cash limits set', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Driver')),
                    DataColumn(label: Text('Max Limit')),
                    DataColumn(label: Text('Current')),
                    DataColumn(label: Text('Remaining')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: limits.map((l) {
                    return DataRow(
                      cells: [
                        DataCell(Text(l.driverName)),
                        DataCell(Text('₹${l.maxCashInHand.toStringAsFixed(2)}')),
                        DataCell(Text('₹${l.currentCash.toStringAsFixed(2)}')),
                        DataCell(Text('₹${l.remaining.toStringAsFixed(2)}')),
                        DataCell(
                          l.isOverLimit
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text('OVER LIMIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                                )
                              : const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showSetLimitDialog(l),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  await CashLimitService.deleteLimit(l.id);
                                },
                                tooltip: 'Delete',
                              ),
                            ],
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
