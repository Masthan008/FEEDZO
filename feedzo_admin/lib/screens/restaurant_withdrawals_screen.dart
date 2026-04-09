import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/restaurant_withdrawal_model.dart';
import '../services/restaurant_withdrawal_service.dart';
import '../widgets/topbar.dart';

class RestaurantWithdrawalsScreen extends StatefulWidget {
  const RestaurantWithdrawalsScreen({super.key});

  @override
  State<RestaurantWithdrawalsScreen> createState() => _RestaurantWithdrawalsScreenState();
}

class _RestaurantWithdrawalsScreenState extends State<RestaurantWithdrawalsScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Restaurant Withdrawals', subtitle: 'Manage restaurant payout requests'),
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
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RestaurantWithdrawalModel>>(
            stream: _selectedStatus == 'all'
                ? RestaurantWithdrawalService.watchAllWithdrawals()
                : RestaurantWithdrawalService.watchWithdrawalsByStatus(_selectedStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final withdrawals = snapshot.data ?? [];

              if (withdrawals.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No withdrawal requests', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Restaurant')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Method')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: withdrawals.map((withdrawal) {
                      return DataRow(
                        cells: [
                          DataCell(Text(withdrawal.restaurantName)),
                          DataCell(
                            Text(
                              '₹${withdrawal.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(withdrawal.method.toUpperCase())),
                          DataCell(_buildStatusChip(withdrawal.status)),
                          DataCell(Text(
                            DateFormat('MMM dd, yyyy').format(withdrawal.createdAt),
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(
                            Row(
                              children: [
                                if (withdrawal.status == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _approveWithdrawal(withdrawal),
                                    tooltip: 'Approve',
                                  ),
                                if (withdrawal.status == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () => _rejectWithdrawal(withdrawal),
                                    tooltip: 'Reject',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blue),
                                  onPressed: () => _showWithdrawalDetails(withdrawal),
                                  tooltip: 'View Details',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'processing':
        color = Colors.blue;
        label = 'Processing';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _approveWithdrawal(RestaurantWithdrawalModel withdrawal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Withdrawal'),
        content: Text('Approve ₹${withdrawal.amount.toStringAsFixed(2)} withdrawal for ${withdrawal.restaurantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await RestaurantWithdrawalService.approveWithdrawal(withdrawal.id, 'admin');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Withdrawal approved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectWithdrawal(RestaurantWithdrawalModel withdrawal) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ₹${withdrawal.amount.toStringAsFixed(2)} withdrawal for ${withdrawal.restaurantName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason')),
                );
                return;
              }
              await RestaurantWithdrawalService.rejectWithdrawal(
                withdrawal.id,
                reasonController.text,
                'admin',
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Withdrawal rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDetails(RestaurantWithdrawalModel withdrawal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal Details'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Restaurant', withdrawal.restaurantName),
              _buildDetailRow('Amount', '₹${withdrawal.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Method', withdrawal.method.toUpperCase()),
              _buildDetailRow('Status', withdrawal.status),
              _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(withdrawal.createdAt)),
              if (withdrawal.processedAt != null)
                _buildDetailRow('Processed', DateFormat('MMM dd, yyyy HH:mm').format(withdrawal.processedAt!)),
              if (withdrawal.processedBy != null)
                _buildDetailRow('Processed By', withdrawal.processedBy!),
              if (withdrawal.rejectionReason != null) ...[
                const SizedBox(height: 8),
                const Text('Rejection Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(withdrawal.rejectionReason!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              const Text('Method Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...withdrawal.methodDetails.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(child: Text(e.value.toString())),
                  ],
                ),
              )),
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
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
