import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class DriverPayoutsScreen extends StatefulWidget {
  const DriverPayoutsScreen({super.key});

  @override
  State<DriverPayoutsScreen> createState() => _DriverPayoutsScreenState();
}

class _DriverPayoutsScreenState extends State<DriverPayoutsScreen> {
  String _selectedFilter = 'all'; // all, pending, verified, rejected

  Stream<QuerySnapshot> get _submissionsStream {
    var query = FirebaseFirestore.instance
        .collection('driverSubmissions')
        .orderBy('submittedAt', descending: true);
    
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
  }

  Future<void> _verifySubmission(String submissionId, String driverId, double amount) async {
    final user = FirebaseFirestore.instance.collection('users').doc('admin').get();
    final adminName = 'Admin'; // In real app, get from auth
    
    await FirebaseFirestore.instance.collection('driverSubmissions').doc(submissionId).update({
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': adminName,
    });
    
    // Also update driver's settlement to reflect verified status
    final settlementRef = FirebaseFirestore.instance.collection('settlements').doc(driverId);
    final settlementDoc = await settlementRef.get();
    if (settlementDoc.exists) {
      final data = settlementDoc.data() as Map<String, dynamic>;
      final submitted = (data['submitted'] as num?)?.toDouble() ?? 0;
      final pending = (data['pending'] as num?)?.toDouble() ?? 0;
      
      await settlementRef.update({
        'pending': (pending - amount).clamp(0, double.infinity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout verified successfully'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    }
  }

  Future<void> _rejectSubmission(String submissionId, String reason) async {
    await FirebaseFirestore.instance.collection('driverSubmissions').doc(submissionId).update({
      'status': 'rejected',
      'verifiedAt': FieldValue.serverTimestamp(),
      'notes': reason,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRejectDialog(String submissionId) {
    final reasonCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
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
            onPressed: () {
              if (reasonCtrl.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _rejectSubmission(submissionId, reasonCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Driver Payouts',
          subtitle: 'Verify and manage driver cash submissions',
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _submissionsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data?.docs ?? [];
              
              // Calculate stats
              double totalPending = 0;
              double totalVerified = 0;
              int pendingCount = 0;
              int verifiedCount = 0;
              
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                final status = data['status'] as String? ?? 'pending';
                
                if (status == 'pending') {
                  totalPending += amount;
                  pendingCount++;
                } else if (status == 'verified') {
                  totalVerified += amount;
                  verifiedCount++;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        _StatCard(
                          label: 'Pending Payouts',
                          value: '₹${totalPending.toStringAsFixed(0)}',
                          count: '$pendingCount submissions',
                          color: AppColors.warning,
                          icon: Icons.pending_actions_rounded,
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          label: 'Verified Today',
                          value: '₹${totalVerified.toStringAsFixed(0)}',
                          count: '$verifiedCount verified',
                          color: AppColors.statusDelivered,
                          icon: Icons.verified_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Filter Chips
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedFilter == 'all',
                          onTap: () => setState(() => _selectedFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Pending',
                          selected: _selectedFilter == 'pending',
                          onTap: () => setState(() => _selectedFilter = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Verified',
                          selected: _selectedFilter == 'verified',
                          onTap: () => setState(() => _selectedFilter = 'verified'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Rejected',
                          selected: _selectedFilter == 'rejected',
                          onTap: () => setState(() => _selectedFilter = 'rejected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Submissions List
                    if (docs.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'all' 
                                  ? 'No driver submissions yet'
                                  : 'No ${_selectedFilter} submissions',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                border: Border(bottom: BorderSide(color: AppColors.border)),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(flex: 2, child: Text('Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                  const Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                  const Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                  const Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                  const Expanded(flex: 2, child: Text('Submitted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                  const Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                                ],
                              ),
                            ),
                            // Table Rows
                            ...docs.asMap().entries.map((entry) {
                              final index = entry.key;
                              final doc = entry.value;
                              final data = doc.data() as Map<String, dynamic>;
                              final isLast = index == docs.length - 1;
                              
                              return _SubmissionRow(
                                doc: doc,
                                isLast: isLast,
                                onVerify: () => _verifySubmission(
                                  doc.id,
                                  data['driverId'] ?? '',
                                  (data['amount'] as num?)?.toDouble() ?? 0,
                                ),
                                onReject: () => _showRejectDialog(doc.id),
                              );
                            }),
                          ],
                        ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withAlpha(180),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isLast;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _SubmissionRow({
    required this.doc,
    required this.isLast,
    required this.onVerify,
    required this.onReject,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final driverName = data['driverName'] ?? 'Unknown';
    final driverPhone = data['driverPhone'] ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final status = data['status'] as String? ?? 'pending';
    final submittedAt = data['submittedAt'] as Timestamp?;

    Color statusColor;
    Color statusBg;
    String statusLabel;
    
    switch (status) {
      case 'verified':
        statusColor = AppColors.statusDelivered;
        statusBg = AppColors.statusDeliveredBg;
        statusLabel = 'Verified';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withAlpha(30);
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.statusPendingBg;
        statusLabel = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    driverName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              driverPhone.isNotEmpty ? driverPhone : '-',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(submittedAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: status == 'pending'
                ? Wrap(
                    spacing: 6,
                    children: [
                      _ActionBtn(
                        label: 'Verify',
                        color: AppColors.statusDelivered,
                        onTap: onVerify,
                      ),
                      _ActionBtn(
                        label: 'Reject',
                        color: AppColors.error,
                        onTap: onReject,
                      ),
                    ],
                  )
                : Text(
                    status == 'verified' ? '✓ Verified' : '✗ Rejected',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
