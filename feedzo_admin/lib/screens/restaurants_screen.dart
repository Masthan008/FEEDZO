import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../widgets/topbar.dart';

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Restaurants', subtitle: 'Manage all partner restaurants'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              final pending = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isApproved'] == false;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (pending.isNotEmpty) _PendingBanner(docs: pending),
                    if (pending.isNotEmpty) const SizedBox(height: 16),
                    if (docs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(children: [
                            const Icon(Icons.store_outlined, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            const Text('No restaurants registered yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                          ]),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          _TableHeader(),
                          ...docs.map((doc) => _RestaurantRow(doc: doc)),
                        ]),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _PendingBanner({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pending_actions_rounded, color: AppColors.statusPending),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusPending)),
            Text(
              '${docs.length} restaurant(s) awaiting review: ${docs.map((d) => (d.data() as Map)['name'] ?? 'Unknown').join(', ')}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ])),
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: docs.expand((doc) {
            final name = (doc.data() as Map)['name'] ?? 'Restaurant';
            return [
              ElevatedButton(
                onPressed: () => _approve(doc.id),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: Text('Approve $name', style: const TextStyle(fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: () => _reject(doc.id),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Reject', style: TextStyle(fontSize: 12)),
              ),
            ];
          }).toList()),
        ],
      ),
    );
  }

  Future<void> _approve(String id) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('restaurants').doc(id), {'isApproved': true});
    batch.update(FirebaseFirestore.instance.collection('users').doc(id), {'status': 'approved'});
    await batch.commit();
  }

  Future<void> _reject(String id) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('restaurants').doc(id), {'isApproved': false});
    batch.update(FirebaseFirestore.instance.collection('users').doc(id), {'status': 'rejected'});
    await batch.commit();
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(children: [
        Expanded(flex: 4, child: Text('Restaurant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Commission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      ]),
    );
  }
}

class _RestaurantRow extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _RestaurantRow({required this.doc});

  @override
  State<_RestaurantRow> createState() => _RestaurantRowState();
}

class _RestaurantRowState extends State<_RestaurantRow> {
  bool _editingCommission = false;
  late TextEditingController _commCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.doc.data() as Map<String, dynamic>;
    final commission = ((d['commission'] as num?) ?? 10).toDouble();
    _commCtrl = TextEditingController(text: commission.toStringAsFixed(0));
  }

  @override
  void dispose() { _commCtrl.dispose(); super.dispose(); }

  Future<void> _saveCommission() async {
    final v = double.tryParse(_commCtrl.text);
    if (v != null && v >= 0 && v <= 50) {
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.doc.id).update({'commission': v});
    }
    setState(() => _editingCommission = false);
  }

  Future<void> _toggleStatus(bool isApproved) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('restaurants').doc(widget.doc.id), {'isApproved': !isApproved});
    batch.update(FirebaseFirestore.instance.collection('users').doc(widget.doc.id), {'status': !isApproved ? 'approved' : 'rejected'});
    await batch.commit();
  }

  Future<void> _releasePayout(double wallet) async {
    if (wallet <= 0) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('restaurants').doc(widget.doc.id), {'wallet': 0});
    batch.set(FirebaseFirestore.instance.collection('transactions').doc(), {
      'restaurantId': widget.doc.id,
      'amount': wallet,
      'type': 'payout',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unknown';
    final email = d['email'] as String? ?? '';
    final isApproved = d['isApproved'] as bool? ?? false;
    final commission = ((d['commission'] as num?) ?? 10).toDouble();
    final wallet = ((d['wallet'] as num?) ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(flex: 4, child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
            Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
        ])),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isApproved ? AppColors.statusDeliveredBg : AppColors.statusPendingBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(isApproved ? 'Active' : 'Pending',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isApproved ? AppColors.statusDelivered : AppColors.statusPending)),
        )),
        Expanded(flex: 2, child: _editingCommission
          ? Row(children: [
              SizedBox(width: 52, child: TextField(controller: _commCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)))),
              const SizedBox(width: 4),
              GestureDetector(onTap: _saveCommission, child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 16)),
            ])
          : GestureDetector(
              onTap: () => setState(() => _editingCommission = true),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('${commission.toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_rounded, size: 12, color: AppColors.textHint),
              ]),
            )),
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rs.${wallet.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: wallet > 0 ? AppColors.primary : AppColors.textHint)),
          const Text('Wallet', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        Expanded(flex: 3, child: Wrap(spacing: 6, runSpacing: 4, children: [
          _Btn(
            label: isApproved ? 'Disable' : 'Approve',
            color: isApproved ? AppColors.error : AppColors.primary,
            onTap: () => _toggleStatus(isApproved),
          ),
          if (wallet > 0)
            _Btn(label: 'Release Rs.${wallet.toStringAsFixed(0)}', color: AppColors.info, onTap: () => _releasePayout(wallet)),
        ])),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
