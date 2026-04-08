import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../widgets/topbar.dart';

/// Admin screen to view all drivers' COD collection and submission status
class DriverCodScreen extends StatelessWidget {
  const DriverCodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TopBar(
            title: 'Driver COD Tracking',
            subtitle: 'Monitor cash collection and submissions',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('settlements')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No settlement data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate totals
                double totalCollected = 0;
                double totalSubmitted = 0;
                double totalPending = 0;

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalCollected += (data['codCollected'] as num?)?.toDouble() ?? 0;
                  totalSubmitted += (data['submitted'] as num?)?.toDouble() ?? 0;
                  totalPending += (data['pending'] as num?)?.toDouble() ?? 0;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          _SummaryCard(
                            title: 'Total Collected',
                            amount: totalCollected,
                            color: AppColors.statusDelivered,
                            icon: Icons.money_rounded,
                          ),
                          const SizedBox(width: 16),
                          _SummaryCard(
                            title: 'Total Submitted',
                            amount: totalSubmitted,
                            color: AppColors.primary,
                            icon: Icons.check_circle_rounded,
                          ),
                          const SizedBox(width: 16),
                          _SummaryCard(
                            title: 'Total Pending',
                            amount: totalPending,
                            color: AppColors.warning,
                            icon: Icons.pending_actions_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Driver List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Driver COD Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${docs.length} drivers',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Driver List
                      ...docs.map((doc) => _DriverCodCard(
                            driverId: doc.id,
                            data: doc.data() as Map<String, dynamic>,
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCodCard extends StatelessWidget {
  final String driverId;
  final Map<String, dynamic> data;

  const _DriverCodCard({
    required this.driverId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final codCollected = (data['codCollected'] as num?)?.toDouble() ?? 0;
    final submitted = (data['submitted'] as num?)?.toDouble() ?? 0;
    final pending = (data['pending'] as num?)?.toDouble() ?? 0;
    final updatedAt = data['updatedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ID: ${driverId.substring(0, driverId.length > 8 ? 8 : driverId.length)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending: ₹${pending.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Collected',
                  value: '₹${codCollected.toStringAsFixed(0)}',
                  color: AppColors.statusDelivered,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Submitted',
                  value: '₹${submitted.toStringAsFixed(0)}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Pending',
                  value: '₹${pending.toStringAsFixed(0)}',
                  color: pending > 0 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (updatedAt != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last updated: ${_formatDate(updatedAt.toDate())}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withAlpha(150),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
