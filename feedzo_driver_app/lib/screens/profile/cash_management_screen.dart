import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../services/settlement_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CashManagementScreen extends StatefulWidget {
  const CashManagementScreen({super.key});

  @override
  State<CashManagementScreen> createState() => _CashManagementScreenState();
}

class _CashManagementScreenState extends State<CashManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverId = authProvider.driverId;

    if (driverId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Management'),
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: SettlementService.watchSettlement(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final settlement = snapshot.data ?? {};
          final codCollected = (settlement['codCollected'] ?? 0).toDouble();
          final pending = (settlement['pending'] ?? 0).toDouble();
          final cashLimit = (settlement['cashLimit'] ?? 5000).toDouble();

          return Column(
            children: [
              _buildBalanceCard(codCollected, pending, cashLimit),
              Expanded(
                child: _buildActionsList(codCollected, pending, cashLimit, driverId!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double codCollected, double pending, double cashLimit) {
    final availableToSubmit = codCollected - pending;
    final percentage = (availableToSubmit / cashLimit * 100).clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash in Hand',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${codCollected.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Pending', '₹${pending.toStringAsFixed(2)}', Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Limit', '₹${cashLimit.toStringAsFixed(2)}', Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 80 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(0)}% of limit',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList(double codCollected, double pending, double cashLimit, String driverId) {
    final availableToSubmit = codCollected - pending;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActionCard(
          title: 'Submit Cash',
          subtitle: 'Submit collected COD to admin',
          icon: Icons.upload,
          color: Colors.green,
          enabled: availableToSubmit > 0,
          onTap: () => _showSubmitDialog(availableToSubmit, driverId),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'View History',
          subtitle: 'View submission history',
          icon: Icons.history,
          color: Colors.blue,
          enabled: true,
          onTap: () {
            // Navigate to history screen
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Cash Limit Info',
          subtitle: 'Maximum cash you can hold: ₹${cashLimit.toStringAsFixed(2)}',
          icon: Icons.info,
          color: Colors.orange,
          enabled: true,
          onTap: () {
            // Show info dialog
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(enabled ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: enabled ? color : Colors.grey),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: enabled ? null : Colors.grey,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  void _showSubmitDialog(double amount, String driverId) {
    final amountController = TextEditingController(text: amount.toStringAsFixed(2));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Cash'),
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
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
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
              final submitAmount = double.tryParse(amountController.text);
              if (submitAmount != null && submitAmount > 0) {
                await SettlementService.submitCash(
                  driverId,
                  submitAmount,
                  notesController.text.isEmpty ? 'Manual submission' : notesController.text,
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
