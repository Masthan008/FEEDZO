import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _coupons = FirebaseFirestore.instance.collection('coupons');
  String _filter = 'all'; // 'all', 'active', 'expired'

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Coupon Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _FilterChip(
                label: 'All',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Active',
                selected: _filter == 'active',
                onTap: () => setState(() => _filter = 'active'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expired',
                selected: _filter == 'expired',
                onTap: () => setState(() => _filter = 'expired'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showCouponDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Coupon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Coupon Grid ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _coupons
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)));
                }

                var docs = snapshot.data?.docs ?? [];

                // Filter
                if (_filter == 'active') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] == true;
                    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                    return isActive &&
                        (expiresAt == null ||
                            DateTime.now().isBefore(expiresAt));
                  }).toList();
                } else if (_filter == 'expired') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] == true;
                    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                    return !isActive ||
                        (expiresAt != null &&
                            DateTime.now().isAfter(expiresAt));
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'all'
                              ? 'No coupons yet'
                              : 'No $_filter coupons',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click "New Coupon" to create one',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _CouponCard(
                      id: doc.id,
                      data: data,
                      onEdit: () =>
                          _showCouponDialog(context, docId: doc.id, data: data),
                      onToggle: () => _toggleCoupon(doc.id, data),
                      onDelete: () => _deleteCoupon(doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle active/inactive ──
  Future<void> _toggleCoupon(String id, Map<String, dynamic> data) async {
    final current = data['isActive'] == true;
    await _coupons.doc(id).update({'isActive': !current});
  }

  // ── Delete coupon ──
  Future<void> _deleteCoupon(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _coupons.doc(id).delete();
    }
  }

  // ── Create / Edit Dialog ──
  Future<void> _showCouponDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? data}) async {
    final isEditing = docId != null;
    final codeCtrl =
        TextEditingController(text: data?['code']?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: data?['description']?.toString() ?? '');
    final valueCtrl = TextEditingController(
        text: (data?['value'] as num?)?.toString() ?? '');
    final minOrderCtrl = TextEditingController(
        text: (data?['minOrder'] as num?)?.toString() ?? '0');
    final maxDiscountCtrl = TextEditingController(
        text: (data?['maxDiscount'] as num?)?.toString() ?? '');
    final usageLimitCtrl = TextEditingController(
        text: (data?['usageLimit'] as num?)?.toString() ?? '0');
    String type = data?['type'] ?? 'flat';
    bool isActive = data?['isActive'] ?? true;
    DateTime? expiresAt = (data?['expiresAt'] as Timestamp?)?.toDate();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Coupon' : 'New Coupon'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code *',
                      hintText: 'e.g. SAVE20',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. 20% off on orders above ₹300',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(
                            labelText: 'Discount Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'flat', child: Text('Flat (₹)')),
                            DropdownMenuItem(
                                value: 'percent', child: Text('Percent (%)')),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => type = v ?? 'flat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: valueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                type == 'flat' ? 'Discount (₹)' : 'Discount (%)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minOrderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Order (₹)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxDiscountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Discount (₹)',
                            hintText: 'Optional',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: usageLimitCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Usage Limit (0 = unlimited)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => expiresAt = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expires At',
                              border: OutlineInputBorder(),
                              suffixIcon:
                                  Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(
                              expiresAt != null
                                  ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                                  : 'No expiry',
                              style: TextStyle(
                                color: expiresAt != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeCtrl.text.trim().toUpperCase();
                if (code.isEmpty || valueCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Code and value are required')),
                  );
                  return;
                }
                final couponData = {
                  'code': code,
                  'description': descCtrl.text.trim(),
                  'type': type,
                  'value': double.tryParse(valueCtrl.text) ?? 0,
                  'minOrder': double.tryParse(minOrderCtrl.text) ?? 0,
                  'maxDiscount': maxDiscountCtrl.text.isEmpty
                      ? null
                      : double.tryParse(maxDiscountCtrl.text),
                  'usageLimit': int.tryParse(usageLimitCtrl.text) ?? 0,
                  'isActive': isActive,
                  if (expiresAt != null)
                    'expiresAt': Timestamp.fromDate(expiresAt!),
                  if (!isEditing) 'usageCount': 0,
                  if (!isEditing)
                    'createdAt': FieldValue.serverTimestamp(),
                };

                if (isEditing) {
                  await _coupons.doc(docId).update(couponData);
                } else {
                  await _coupons.add(couponData);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coupon Card ──
class _CouponCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CouponCard({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final code = data['code'] ?? '';
    final desc = data['description'] ?? '';
    final type = data['type'] ?? 'flat';
    final value = (data['value'] as num?)?.toDouble() ?? 0;
    final isActive = data['isActive'] == true;
    final usageCount = (data['usageCount'] as num?)?.toInt() ?? 0;
    final usageLimit = (data['usageLimit'] as num?)?.toInt() ?? 0;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    final isExpired =
        expiresAt != null && DateTime.now().isAfter(expiresAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive && !isExpired
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code + Status
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive && !isExpired
                        ? [AppColors.primary, const Color(0xFF7C3AED)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red.shade50
                      : isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isExpired
                      ? 'EXPIRED'
                      : isActive
                          ? 'ACTIVE'
                          : 'INACTIVE',
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red.shade700
                        : isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value
          Text(
            type == 'percent' ? '${value.toInt()}% OFF' : '₹${value.toInt()} OFF',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),

          // Stats
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                usageLimit > 0
                    ? '$usageCount / $usageLimit used'
                    : '$usageCount used',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              if (expiresAt != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Edit',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: isActive
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      color: AppColors.error, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──
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
    return InkWell(
      onTap: onTap,
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
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
