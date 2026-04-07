import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../widgets/topbar.dart';
import 'customer_detail_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TopBar(title: 'Users', subtitle: 'Manage all registered users'),
          Container(
            color: AppColors.surface,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Customers'),
                Tab(text: 'Restaurants'),
                Tab(text: 'Drivers'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const Expanded(
            child: TabBarView(
              children: [
                _UserList(filter: 'pending'),
                _UserList(filter: 'customer'),
                _UserList(filter: 'restaurant'),
                _UserList(filter: 'driver'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String filter;
  const _UserList({required this.filter});

  Stream<QuerySnapshot> get _stream {
    final col = FirebaseFirestore.instance.collection('users');
    if (filter == 'pending') return col.where('status', isEqualTo: 'pending').snapshots();
    return col.where('role', isEqualTo: filter).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  filter == 'pending' ? 'No pending approvals' : 'No ${filter}s registered yet',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }
        final docs = snap.data!.docs;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _TableHeader(showApproval: filter == 'pending'),
                ...docs.map((doc) => _UserRow(
                  doc: doc, 
                  showApproval: filter == 'pending',
                  isCustomer: filter == 'customer',
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool showApproval;
  const _TableHeader({required this.showApproval});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        const Expanded(flex: 3, child: Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const Expanded(flex: 4, child: Text('Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const Expanded(flex: 2, child: Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const Expanded(flex: 3, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      ]),
    );
  }
}

class _UserRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool showApproval;
  final bool isCustomer;
  
  const _UserRow({required this.doc, required this.showApproval, this.isCustomer = false});

  Future<void> _approve() => FirebaseFirestore.instance
      .collection('users').doc(doc.id).update({'status': 'approved'});

  Future<void> _reject() => FirebaseFirestore.instance
      .collection('users').doc(doc.id).update({'status': 'rejected'});

  void _viewDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: doc.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? 'Unknown';
    final email = d['email'] as String? ?? '';
    final phone = d['phone'] as String? ?? '';
    final role = d['role'] as String? ?? 'customer';
    final status = d['status'] as String? ?? 'pending';

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'approved': statusColor = AppColors.statusDelivered; statusBg = AppColors.statusDeliveredBg;
      case 'rejected': statusColor = AppColors.error; statusBg = AppColors.statusCancelledBg;
      default: statusColor = AppColors.warning; statusBg = AppColors.statusPendingBg;
    }

    Color roleColor;
    switch (role) {
      case 'driver': roleColor = AppColors.info;
      case 'restaurant': roleColor = const Color(0xFF7C3AED);
      case 'admin': roleColor = AppColors.error;
      default: roleColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(role, style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.w600)),
        )),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
        )),
        Expanded(flex: 3, child: Wrap(spacing: 6, children: [
          if (showApproval) ...[
            _Btn(label: 'Approve', color: AppColors.primary, onTap: _approve),
            _Btn(label: 'Reject', color: AppColors.error, onTap: _reject),
          ] else if (isCustomer && role == 'customer')
            _Btn(label: 'View Details', color: AppColors.info, onTap: () => _viewDetails(context)),
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}