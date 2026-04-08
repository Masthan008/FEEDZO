import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../widgets/topbar.dart';
import 'drivers/driver_cod_screen.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Drivers',
          subtitle: 'Monitor driver activity and assignments',
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverCodScreen()),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('COD Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDocs = snap.data?.docs ?? [];
              final filtered = _filter == 'all'
                  ? allDocs
                  : allDocs.where((d) => (d.data() as Map)['status'] == _filter).toList();

              final available = allDocs.where((d) => (d.data() as Map)['status'] == 'available').length;
              final busy = allDocs.where((d) => (d.data() as Map)['status'] == 'busy').length;
              final offline = allDocs.where((d) => (d.data() as Map)['status'] == 'offline').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Summary cards
                    Row(children: [
                      _SummaryCard(label: 'Total', value: '${allDocs.length}', icon: Icons.delivery_dining_rounded, color: AppColors.primary),
                      const SizedBox(width: 16),
                      _SummaryCard(label: 'Available', value: '$available', icon: Icons.check_circle_rounded, color: AppColors.statusDelivered),
                      const SizedBox(width: 16),
                      _SummaryCard(label: 'Busy', value: '$busy', icon: Icons.directions_bike_rounded, color: AppColors.info),
                      const SizedBox(width: 16),
                      _SummaryCard(label: 'Offline', value: '$offline', icon: Icons.offline_bolt_rounded, color: AppColors.textSecondary),
                    ]),
                    const SizedBox(height: 16),
                    // Filter chips
                    Row(children: [
                      _FilterChip(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Available', selected: _filter == 'available', onTap: () => setState(() => _filter = 'available')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Busy', selected: _filter == 'busy', onTap: () => setState(() => _filter = 'busy')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Offline', selected: _filter == 'offline', onTap: () => setState(() => _filter = 'offline')),
                    ]),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: const Center(child: Text('No drivers found', style: TextStyle(color: AppColors.textSecondary))),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Column(children: [
                          _TableHeader(),
                          ...filtered.map((doc) => _DriverRow(doc: doc)),
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
        Expanded(flex: 4, child: Text('Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Today Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('COD Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Approved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      ]),
    );
  }
}

class _DriverRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _DriverRow({required this.doc});

  Future<void> _approve() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('drivers').doc(doc.id), {'isApproved': true});
    batch.update(FirebaseFirestore.instance.collection('users').doc(doc.id), {'status': 'approved'});
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unknown';
    final phone = d['phone'] as String? ?? '';
    final vehicle = d['vehicle'] as String? ?? '';
    final status = d['status'] as String? ?? 'offline';
    final todayOrders = (d['todayOrders'] as num?)?.toInt() ?? 0;
    final codCollected = ((d['codCollected'] as num?) ?? 0).toDouble();
    final isApproved = d['isApproved'] as bool? ?? false;

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'available': statusColor = AppColors.statusDelivered; statusBg = AppColors.statusDeliveredBg;
      case 'busy': statusColor = AppColors.statusPreparing; statusBg = AppColors.statusPreparingBg;
      default: statusColor = AppColors.textSecondary; statusBg = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(flex: 4, child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
            Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            if (vehicle.isNotEmpty) Text(vehicle, style: const TextStyle(fontSize: 11, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
          ])),
        ])),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
        )),
        Expanded(flex: 2, child: Text('$todayOrders', style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text('Rs.${codCollected.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: codCollected > 0 ? AppColors.warning : AppColors.textHint))),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isApproved ? AppColors.statusDeliveredBg : AppColors.statusPendingBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(isApproved ? 'Yes' : 'Pending',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isApproved ? AppColors.statusDelivered : AppColors.statusPending)),
        )),
        Expanded(flex: 2, child: Wrap(spacing: 6, children: [
          if (!isApproved)
            _Btn(label: 'Approve', color: AppColors.primary, onTap: _approve),
        ])),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
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
