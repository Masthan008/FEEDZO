import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

/// Admin screen for managing refund requests from customers.
/// Shows pending/approved/rejected refunds with approval/rejection actions.
class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});
  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  final _refunds = FirebaseFirestore.instance.collection('refunds');
  String _filter = 'pending'; // 'pending', 'approved', 'rejected', 'all'

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.currency_exchange_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Refund Management',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              ..._buildFilterChips(),
            ],
          ),
          const SizedBox(height: 24),

          // Refunds table
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filter == 'all'
                  ? _refunds.orderBy('createdAt', descending: true).snapshots()
                  : _refunds
                      .where('status', isEqualTo: _filter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'pending'
                              ? 'No pending refunds'
                              : 'No $_filter refunds',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppShape.large,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.surfaceVariant),
                      columns: const [
                        DataColumn(label: Text('Order ID',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Customer',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Amount',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Reason',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Status',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Date',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                        DataColumn(label: Text('Actions',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final status = d['status'] ?? 'pending';
                        final createdAt =
                            (d['createdAt'] as Timestamp?)?.toDate();

                        return DataRow(cells: [
                          DataCell(Text('#${(d['orderId'] ?? doc.id).toString().substring(0, 8)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13))),
                          DataCell(Text(d['customerName'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text('₹${(d['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13))),
                          DataCell(SizedBox(
                            width: 160,
                            child: Text(d['reason'] ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          )),
                          DataCell(_StatusBadge(status: status)),
                          DataCell(Text(
                            createdAt != null
                                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                : '-',
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(
                            status == 'pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ActionBtn(
                                        label: 'Approve',
                                        color: AppColors.success,
                                        onTap: () => _updateStatus(
                                            doc.id, 'approved'),
                                      ),
                                      const SizedBox(width: 6),
                                      _ActionBtn(
                                        label: 'Reject',
                                        color: AppColors.error,
                                        onTap: () => _updateStatus(
                                            doc.id, 'rejected'),
                                      ),
                                    ],
                                  )
                                : const Text('-',
                                    style: TextStyle(color: AppColors.textHint)),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = ['pending', 'approved', 'rejected', 'all'];
    return filters.map((f) {
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: InkWell(
          onTap: () => setState(() => _filter = f),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade300),
            ),
            child: Text(
              f[0].toUpperCase() + f.substring(1),
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _updateStatus(String docId, String status) async {
    final refundDoc = await _refunds.doc(docId).get();
    if (!refundDoc.exists) return;

    final refundData = refundDoc.data() as Map<String, dynamic>;
    final customerId = refundData['customerId'] as String?;
    final amount = (refundData['amount'] as num?)?.toDouble() ?? 0;
    final orderId = refundData['orderId'] as String?;

    if (status == 'approved' && customerId != null) {
      // Credit customer wallet
      final walletRef = FirebaseFirestore.instance.collection('customerWallets').doc(customerId);
      await walletRef.set({
        'balance': FieldValue.increment(amount),
        'totalRefunds': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create transaction record
      await walletRef.collection('transactions').add({
        'type': 'refund',
        'amount': amount,
        'description': 'Refund for order #${orderId ?? docId}',
        'refundId': docId,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update order status if orderId exists
      if (orderId != null) {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'refundStatus': 'approved',
          'refundAmount': amount,
          'refundedAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (status == 'rejected' && orderId != null) {
      // Update order status to reflect rejected refund
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'refundStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    }

    // Update refund status
    await _refunds.doc(docId).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'approved'
        ? AppColors.success
        : status == 'rejected'
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
