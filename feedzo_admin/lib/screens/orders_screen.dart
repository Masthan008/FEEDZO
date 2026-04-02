import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../widgets/topbar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _filter;

  Stream<QuerySnapshot> get _stream {
    final col = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);
    if (_filter == null) return col.snapshots();
    return col.where('status', isEqualTo: _filter).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Orders', subtitle: 'Manage and assign all platform orders'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              final delayed = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (data['status'] != 'placed') return false;
                final created = (data['createdAt'] as Timestamp?)?.toDate();
                if (created == null) return false;
                return DateTime.now().difference(created).inMinutes > 20 && data['driverId'] == null;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (delayed.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Text('${delayed.length} delayed order${delayed.length > 1 ? 's' : ''} — pending 20+ min without driver',
                              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Placed', selected: _filter == 'placed', onTap: () => setState(() => _filter = 'placed')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Preparing', selected: _filter == 'preparing', onTap: () => setState(() => _filter = 'preparing')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Out for Delivery', selected: _filter == 'picked', onTap: () => setState(() => _filter = 'picked')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Delivered', selected: _filter == 'delivered', onTap: () => setState(() => _filter = 'delivered')),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary))),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Column(children: [
                          _TableHeader(),
                          ...docs.map((doc) => _OrderRow(doc: doc)),
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
        Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Restaurant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text('Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      ]),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _OrderRow({required this.doc});

  Future<void> _updateStatus(String status) =>
      FirebaseFirestore.instance.collection('orders').doc(doc.id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final orderId = doc.id;
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase();
    final customerId = d['customerId'] as String? ?? '';
    final restaurantName = d['restaurantName'] as String? ?? 'Unknown';
    final totalAmount = ((d['totalAmount'] as num?) ?? 0).toDouble();
    final paymentType = d['paymentType'] as String? ?? 'online';
    final status = d['status'] as String? ?? 'placed';
    final driverName = d['driverName'] as String?;
    final driverId = d['driverId'] as String?;

    final created = (d['createdAt'] as Timestamp?)?.toDate();
    final isDelayed = status == 'placed' && driverId == null &&
        created != null && DateTime.now().difference(created).inMinutes > 20;

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'placed': statusColor = AppColors.statusPending; statusBg = AppColors.statusPendingBg;
      case 'preparing': statusColor = AppColors.statusPreparing; statusBg = AppColors.statusPreparingBg;
      case 'picked': statusColor = AppColors.info; statusBg = const Color(0xFFDBEAFE);
      case 'delivered': statusColor = AppColors.statusDelivered; statusBg = AppColors.statusDeliveredBg;
      case 'cancelled': statusColor = AppColors.error; statusBg = AppColors.statusCancelledBg;
      default: statusColor = AppColors.textSecondary; statusBg = AppColors.background;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDelayed ? AppColors.error.withValues(alpha: 0.03) : null,
        border: Border(
          bottom: const BorderSide(color: AppColors.border),
          left: isDelayed ? const BorderSide(color: AppColors.error, width: 3) : BorderSide.none,
        ),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Row(children: [
          Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
          if (isDelayed) ...[const SizedBox(width: 4), const Icon(Icons.warning_rounded, color: AppColors.error, size: 14)],
        ])),
        Expanded(flex: 3, child: Text(customerId.length > 8 ? '...${customerId.substring(customerId.length - 8)}' : customerId,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(restaurantName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text('Rs.${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: paymentType == 'cod' ? AppColors.statusPendingBg : AppColors.statusDeliveredBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(paymentType.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: paymentType == 'cod' ? AppColors.statusPending : AppColors.statusDelivered)),
        )),
        Expanded(flex: 3, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
        )),
        Expanded(flex: 3, child: driverName != null
          ? Row(children: [
              const Icon(Icons.delivery_dining_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(driverName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            ])
          : const Text('Unassigned', style: TextStyle(fontSize: 12, color: AppColors.textHint))),
        Expanded(flex: 2, child: Wrap(spacing: 4, runSpacing: 4, children: [
          if (driverId == null && status != 'cancelled' && status != 'delivered')
            _Btn(label: 'Assign', color: AppColors.primary, onTap: () => _showAssignModal(context)),
          if (status == 'preparing')
            _Btn(label: 'Pick', color: AppColors.info, onTap: () => _updateStatus('picked')),
          if (status == 'picked')
            _Btn(label: 'Deliver', color: AppColors.statusDelivered, onTap: () => _updateStatus('delivered')),
        ])),
      ]),
    );
  }

  void _showAssignModal(BuildContext context) {
    showDialog(context: context, builder: (_) => _AssignDriverModal(orderId: doc.id));
  }
}

class _AssignDriverModal extends StatefulWidget {
  final String orderId;
  const _AssignDriverModal({required this.orderId});

  @override
  State<_AssignDriverModal> createState() => _AssignDriverModalState();
}

class _AssignDriverModalState extends State<_AssignDriverModal> {
  String? _selectedId;
  bool _assigning = false;

  Future<void> _assign(Map<String, dynamic> driver, String driverId) async {
    setState(() => _assigning = true);
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'driverId': driverId,
      'driverName': driver['name'],
      'status': 'preparing',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({'status': 'busy'});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Assign Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('drivers').where('status', isEqualTo: 'available').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final drivers = snap.data!.docs;
              if (drivers.isEmpty) {
                return const Padding(padding: EdgeInsets.all(20), child: Text('No available drivers', style: TextStyle(color: AppColors.textSecondary)));
              }
              return Column(children: [
                ...drivers.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? 'Driver';
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = d.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedId == d.id ? AppColors.primarySurface : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _selectedId == d.id ? AppColors.primary : AppColors.border, width: _selectedId == d.id ? 2 : 1),
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(data['phone'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                        if (_selectedId == d.id) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _selectedId == null || _assigning ? null : () {
                      final driver = drivers.firstWhere((d) => d.id == _selectedId);
                      _assign(driver.data() as Map<String, dynamic>, driver.id);
                    },
                    child: _assigning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Assign Driver'),
                  ),
                ]),
              ]);
            },
          ),
        ]),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
