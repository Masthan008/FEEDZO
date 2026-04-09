import 'package:flutter/material.dart';
import '../../models/payout_request_model.dart';
import '../../services/payout_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PayoutRequestsScreen extends StatefulWidget {
  const PayoutRequestsScreen({super.key});

  @override
  State<PayoutRequestsScreen> createState() => _PayoutRequestsScreenState();
}

class _PayoutRequestsScreenState extends State<PayoutRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final restaurantId = authProvider.restaurantId;

    if (restaurantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Requests'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildBalanceCard(restaurantId),
          Expanded(
            child: StreamBuilder<List<PayoutRequestModel>>(
              stream: PayoutService.watchPayouts(restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final payouts = snapshot.data ?? [];

                if (payouts.isEmpty) {
                  return const Center(
                    child: Text('No payout requests yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payouts.length,
                  itemBuilder: (context, index) {
                    return _buildPayoutCard(payouts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPayoutDialog(restaurantId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(String restaurantId) {
    return FutureBuilder<double>(
      future: PayoutService.getAvailableBalance(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final balance = snapshot.data ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutCard(PayoutRequestModel payout) {
    final statusColor = _getStatusColor(payout.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(payout.status),
            color: statusColor,
          ),
        ),
        title: Text('₹${payout.amount.toStringAsFixed(2)}'),
        subtitle: Text('Requested on ${_formatDate(payout.requestedAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payout.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPayoutDialog(String restaurantId) {
    final amountController = TextEditingController();
    final bankAccountController = TextEditingController();
    final ifscCodeController = TextEditingController();
    final accountHolderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 16),
              TextField(
                controller: bankAccountController,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ifscCodeController,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountHolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await PayoutService.requestPayout(
                  restaurantId: restaurantId,
                  restaurantName: authProvider.restaurant?.name ?? 'Restaurant',
                  amount: amount,
                  bankAccount: bankAccountController.text,
                  ifscCode: ifscCodeController.text,
                  accountHolderName: accountHolderNameController.text,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
