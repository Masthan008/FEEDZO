import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/wallet_provider.dart';
import '../../data/mock_data.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.price_change_outlined),
            tooltip: 'Hike Charges',
            onPressed: () => Navigator.pushNamed(context, '/hike-charges'),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => _showBankDialog(context, wallet),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${wallet.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _BalanceStat(
                        label: 'Pending Payout',
                        value: '₹${wallet.pendingPayout.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 24),
                      _BalanceStat(
                        label: 'Total Earnings',
                        value: '₹${wallet.totalEarnings.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, wallet),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Withdraw Funds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bank account
            if (wallet.hasBankAccount) ...[
              const Text(
                'Bank Account',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    wallet.bankName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '••••${wallet.accountNumber.length > 4 ? wallet.accountNumber.substring(wallet.accountNumber.length - 4) : wallet.accountNumber}',
                  ),
                  trailing: TextButton(
                    onPressed: () => _showBankDialog(context, wallet),
                    child: const Text('Edit'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Transactions
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...wallet.transactions.map((t) => _TransactionTile(transaction: t)),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletProvider wallet) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: ₹${wallet.balance.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
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
              final amount = double.tryParse(ctrl.text);
              final user = FirebaseAuth.instance.currentUser;
              if (amount != null && amount > 0 && user != null) {
                await wallet.requestWithdrawal(amount, user.uid);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Withdrawal of ₹${amount.toStringAsFixed(0)} initiated',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showBankDialog(BuildContext context, WalletProvider wallet) {
    final bankCtrl = TextEditingController(
      text: wallet.hasBankAccount ? wallet.bankName : '',
    );
    final accCtrl = TextEditingController(
      text: wallet.hasBankAccount ? wallet.accountNumber : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wallet.hasBankAccount ? 'Edit Bank Account' : 'Add Bank Account',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: bankCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (bankCtrl.text.isNotEmpty && accCtrl.text.isNotEmpty) {
                  wallet.saveBankAccount(bankCtrl.text, accCtrl.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Bank Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isEarning = transaction.type == TransactionType.earning;
    final isWithdrawal = transaction.type == TransactionType.withdrawal;
    final color = isEarning
        ? AppColors.primary
        : isWithdrawal
        ? const Color(0xFF2563EB)
        : AppColors.error;
    final icon = isEarning
        ? Icons.arrow_downward
        : isWithdrawal
        ? Icons.arrow_upward
        : Icons.remove_circle_outline;
    final prefix = isEarning ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('MMM d • hh:mm a').format(transaction.date),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (transaction.commission != null && transaction.commission! > 0)
              Text(
                '₹${transaction.commission!.toStringAsFixed(0)} commission',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
