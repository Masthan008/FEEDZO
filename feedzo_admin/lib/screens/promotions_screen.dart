import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});
  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxUsesController = TextEditingController();
  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Promotions',
          subtitle: 'Manage promotional campaigns',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Promotion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Metrics cards
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final coupons = snapshot.data?.docs ?? [];
            
            int activePromotions = 0;
            int couponUsage = 0;
            double totalDiscount = 0;

            for (var couponDoc in coupons) {
              final data = couponDoc.data() as Map<String, dynamic>;
              if (data['isActive'] == true) {
                activePromotions++;
              }
              couponUsage += (data['usageCount'] as num?)?.toInt() ?? 0;
              totalDiscount += (data['discountValue'] as num?)?.toDouble() ?? 0;
            }

            final conversionRate = couponUsage > 0 ? (couponUsage / (couponUsage + 100) * 100).toStringAsFixed(0) : '0';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 140,
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildPromoCard(
                      title: 'Active Promotions',
                      icon: Icons.campaign,
                      color: Colors.blue,
                      value: activePromotions.toString(),
                      subtitle: 'Currently running',
                    ),
                    _buildPromoCard(
                      title: 'Coupon Usage',
                      icon: Icons.local_offer,
                      color: Colors.green,
                      value: _formatNumber(couponUsage),
                      subtitle: 'Coupons used',
                    ),
                    _buildPromoCard(
                      title: 'Discount Value',
                      icon: Icons.discount,
                      color: Colors.orange,
                      value: '₹${_formatCurrency(totalDiscount)}',
                      subtitle: 'Total discounts',
                    ),
                    _buildPromoCard(
                      title: 'Conversion Rate',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                      value: '$conversionRate%',
                      subtitle: 'Promo conversion',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Promotions list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final coupons = snapshot.data?.docs ?? [];

              if (coupons.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No promotions yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Discount')),
                    DataColumn(label: Text('Usage')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Valid Until')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: coupons.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    final usageCount = (data['usageCount'] as num?)?.toInt() ?? 0;
                    final maxUses = (data['maxUses'] as num?)?.toInt();
                    final validUntil = data['validUntil'] as Timestamp?;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            data['code'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(Text(data['description'] ?? 'N/A')),
                        DataCell(Text(
                          '${_discountType == 'percentage' ? '' : '₹'}${data['discountValue']}${_discountType == 'percentage' ? '%' : ''}',
                        )),
                        DataCell(Text('$usageCount${maxUses != null ? '/$maxUses' : ''}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          validUntil != null ? DateFormat('MMM dd, yyyy').format(validUntil.toDate()) : 'No expiry',
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditDialog(doc),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.toggle_on : Icons.toggle_off,
                                  size: 18,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                onPressed: () => _togglePromotion(doc.id, !isActive),
                                tooltip: isActive ? 'Deactivate' : 'Activate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _deletePromotion(doc.id),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog() async {
    _codeController.clear();
    _descriptionController.clear();
    _discountController.clear();
    _minOrderController.clear();
    _maxUsesController.clear();
    _startDate = null;
    _endDate = null;
    _discountType = 'percentage';

    await _showPromotionDialog(null);
  }

  Future<void> _showEditDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    _codeController.text = data['code'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _discountController.text = (data['discountValue'] ?? 0).toString();
    _minOrderController.text = (data['minOrderValue'] ?? 0).toString();
    _maxUsesController.text = (data['maxUses'] ?? '').toString();
    _discountType = data['discountType'] ?? 'percentage';
    _startDate = (data['validFrom'] as Timestamp?)?.toDate();
    _endDate = (data['validUntil'] as Timestamp?)?.toDate();

    await _showPromotionDialog(doc.id);
  }

  Future<void> _showPromotionDialog(String? docId) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? 'Create Promotion' : 'Edit Promotion'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Promo Code *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., SUMMER20',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _discountType,
                    decoration: const InputDecoration(
                      labelText: 'Discount Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                      DropdownMenuItem(value: 'flat', child: Text('Flat Amount (₹)')),
                    ],
                    onChanged: (v) => setDialogState(() => _discountType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Discount Value *',
                      border: OutlineInputBorder(),
                      suffixText: _discountType == 'percentage' ? '%' : '₹',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Order Value (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maxUsesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Uses (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => _startDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Valid From',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => _endDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Valid Until',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _savePromotion(docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePromotion(String? docId) async {
    if (_codeController.text.isEmpty || _discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code and discount value are required')),
      );
      return;
    }

    final discountValue = double.tryParse(_discountController.text) ?? 0;
    final minOrderValue = double.tryParse(_minOrderController.text) ?? 0;
    final maxUses = _maxUsesController.text.isNotEmpty ? int.tryParse(_maxUsesController.text) : null;

    final promotionData = {
      'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim(),
      'discountType': _discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxUses': maxUses,
      'usageCount': 0,
      'isActive': true,
      'validFrom': _startDate != null ? Timestamp.fromDate(_startDate!) : FieldValue.serverTimestamp(),
      'validUntil': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (docId == null) {
        await FirebaseFirestore.instance.collection('coupons').add(promotionData);
      } else {
        await FirebaseFirestore.instance.collection('coupons').doc(docId).update(promotionData);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docId == null ? 'Promotion created successfully' : 'Promotion updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePromotion(String docId, bool isActive) async {
    await FirebaseFirestore.instance.collection('coupons').doc(docId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deletePromotion(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text('Are you sure you want to delete this promotion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('coupons').doc(docId).delete();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildPromoCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
