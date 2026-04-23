import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

/// Admin screen for managing driver incentives — peak pay, challenges, bonuses.
class IncentivesScreen extends StatefulWidget {
  const IncentivesScreen({super.key});
  @override
  State<IncentivesScreen> createState() => _IncentivesScreenState();
}

class _IncentivesScreenState extends State<IncentivesScreen> {
  final _db = FirebaseFirestore.instance.collection('incentives');

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
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.warning, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Driver Incentives',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Incentive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Incentives grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No incentives yet',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Create incentives to motivate drivers',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) =>
                      _IncentiveCard(doc: docs[i], onDelete: () => _delete(docs[i].id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _db.doc(id).delete();
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'peak_pay'; // 'peak_pay', 'challenge', 'bonus'
    String target = '5'; // orders to complete

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Incentive'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: AppShape.small,
                        borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'peak_pay', child: Text('Peak Pay')),
                    DropdownMenuItem(
                        value: 'challenge', child: Text('Challenge')),
                    DropdownMenuItem(value: 'bonus', child: Text('Bonus')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Lunch Rush Bonus',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: AppShape.small,
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: AppShape.small,
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: AppShape.small,
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    if (type == 'challenge') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setDialogState(() => target = v),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Target Orders',
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                                borderRadius: AppShape.small,
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                await _db.add({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': type,
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'targetOrders': int.tryParse(target) ?? 5,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncentiveCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onDelete;
  const _IncentiveCard({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final type = d['type'] ?? 'bonus';
    final isActive = d['isActive'] ?? true;
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;
    final totalPaid = (d['totalPaid'] as num?)?.toDouble() ?? 0;
    final qualifiedDrivers = (d['qualifiedDrivers'] as int?) ?? 0;

    final typeColor = type == 'peak_pay'
        ? AppColors.warning
        : type == 'challenge'
            ? AppColors.info
            : AppColors.success;
    final typeIcon = type == 'peak_pay'
        ? Icons.flash_on_rounded
        : type == 'challenge'
            ? Icons.flag_rounded
            : Icons.card_giftcard_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppShape.large,
        border: Border.all(
            color: isActive
                ? typeColor.withValues(alpha: 0.3)
                : AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: AppShape.small,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      type.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              // Toggle active
              Switch(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    doc.reference.update({'isActive': v}),
              ),
            ],
          ),
          const Spacer(),
          if ((d['description'] as String?)?.isNotEmpty == true)
            Text(
              d['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          const Spacer(),
          Row(
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: typeColor),
              ),
              if (type == 'challenge') ...[
                const SizedBox(width: 8),
                Text(
                  'for ${d['targetOrders'] ?? 5} orders',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Qualified',
                value: qualifiedDrivers.toString(),
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Paid',
                value: '₹${totalPaid.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
              const Spacer(),
              if (isActive)
                TextButton.icon(
                  onPressed: () => _calculateIncentives(context, doc),
                  icon: const Icon(Icons.calculate, size: 16),
                  label: const Text('Calculate'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _calculateIncentives(BuildContext context, QueryDocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    final type = d['type'] ?? 'bonus';
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;
    final targetOrders = (d['targetOrders'] as int?) ?? 5;
    final db = FirebaseFirestore.instance;

    try {
      // Get all drivers
      final drivers = await db.collection('drivers').get();
      int qualifiedCount = 0;
      double totalPayout = 0;

      for (final driver in drivers.docs) {
        final driverId = driver.id;
        
        // Calculate based on incentive type
        bool qualified = false;
        
        if (type == 'peak_pay') {
          // Peak pay: check if driver is online during peak hours
          final driverData = driver.data() as Map<String, dynamic>;
          qualified = driverData['isOnline'] == true;
        } else if (type == 'challenge') {
          // Challenge: check if driver completed target orders this month
          final now = DateTime.now();
          final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
          
          final orders = await db
              .collection('orders')
              .where('driverId', isEqualTo: driverId)
              .where('status', isEqualTo: 'delivered')
              .where('deliveredAt', isGreaterThan: oneMonthAgo)
              .get();
          
          qualified = orders.docs.length >= targetOrders;
        } else {
          // Bonus: all active drivers qualify
          final driverData = driver.data() as Map<String, dynamic>;
          qualified = driverData['isActive'] == true;
        }

        if (qualified) {
          qualifiedCount++;
          totalPayout += amount;
          
          // Add to driver earnings
          await db.collection('driverEarnings').doc(driverId).set({
            'incentiveAmount': FieldValue.increment(amount),
            'totalEarnings': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Update incentive stats
      await doc.reference.update({
        'qualifiedDrivers': qualifiedCount,
        'totalPaid': FieldValue.increment(totalPayout),
        'lastCalculatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calculated: $qualifiedCount drivers qualified, ₹${totalPayout.toStringAsFixed(0)} distributed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating incentives: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
