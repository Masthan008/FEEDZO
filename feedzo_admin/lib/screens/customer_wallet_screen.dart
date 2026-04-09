import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/customer_wallet_model.dart';
import '../services/customer_wallet_service.dart';
import '../widgets/topbar.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Customer Wallets', subtitle: 'Manage customer wallet balances'),
        Expanded(
          child: StreamBuilder<List<CustomerWalletModel>>(
            stream: CustomerWalletService.watchAllWallets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final wallets = snapshot.data ?? [];

              if (wallets.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No customer wallets yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Customer ID')),
                      DataColumn(label: Text('Balance')),
                      DataColumn(label: Text('Transactions')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: wallets.map((wallet) {
                      return DataRow(
                        cells: [
                          DataCell(Text(wallet.customerId)),
                          DataCell(
                            Text(
                              '₹${wallet.balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          DataCell(Text('${wallet.transactions.length}')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _showAddFundsDialog(wallet.customerId),
                                  tooltip: 'Add Funds',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.orange),
                                  onPressed: () => _showDeductFundsDialog(wallet.customerId),
                                  tooltip: 'Deduct Funds',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history, color: Colors.blue),
                                  onPressed: () => _showTransactionHistory(wallet),
                                  tooltip: 'View History',
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

  void _showAddFundsDialog(String customerId) {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (Optional)',
                border: OutlineInputBorder(),
              ),
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                await CustomerWalletService.addFunds(
                  customerId,
                  amount,
                  referenceController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funds added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeductFundsDialog(String customerId) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(text: 'Admin deduction');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deduct Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                await CustomerWalletService.deductFunds(
                  customerId,
                  amount,
                  descriptionController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funds deducted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deduct'),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(CustomerWalletModel wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction History'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: wallet.transactions.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.builder(
                  itemCount: wallet.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = wallet.transactions[index];
                    return ListTile(
                      leading: Icon(
                        tx.type == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: tx.type == 'credit' ? Colors.green : Colors.red,
                      ),
                      title: Text(tx.description ?? 'Transaction'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(tx.createdAt),
                      ),
                      trailing: Text(
                        '${tx.type == 'credit' ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.type == 'credit' ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
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
}
