import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../core/theme.dart';
import '../widgets/topbar.dart';
import '../services/restaurant_admin_service.dart';
import 'restaurants/restaurant_detail_screen.dart';
import 'restaurants/restaurant_form_dialog.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final RestaurantAdminService _service = RestaurantAdminService();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, open, closed, pending
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddRestaurantDialog() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const RestaurantFormDialog(),
    );

    if (result != null) {
      final id = await _service.createRestaurant(
        name: result['name'],
        email: result['email'],
        phone: result['phone'],
        cuisine: result['cuisine'],
        address: result['address'],
        password: result['password'],
        commissionRate: result['commissionRate'] ?? 10.0,
        fssaiNumber: result['fssaiNumber'],
        gstNumber: result['gstNumber'],
        panNumber: result['panNumber'],
        isApproved: result['isApproved'] ?? true,
      );

      if (id != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant created successfully'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          title: 'Restaurants',
          subtitle: 'Manage all partner restaurants',
          actions: [
            ElevatedButton.icon(
              onPressed: _showAddRestaurantDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Restaurant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('restaurants').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              
              // Filter logic
              var filtered = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final matchesSearch = _searchQuery.isEmpty ||
                    (data['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                    (data['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                
                final isApproved = data['isApproved'] as bool? ?? false;
                final isOpen = data['isOpen'] as bool? ?? false;
                
                bool matchesStatus = _filterStatus == 'all';
                if (_filterStatus == 'pending') matchesStatus = !isApproved;
                if (_filterStatus == 'open') matchesStatus = isApproved && isOpen;
                if (_filterStatus == 'closed') matchesStatus = isApproved && !isOpen;
                
                return matchesSearch && matchesStatus;
              }).toList();
              
              final pending = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isApproved'] == false;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search and Filter Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search restaurants...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter Dropdown
                        DropdownButton<String>(
                          value: _filterStatus,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Status')),
                            DropdownMenuItem(value: 'open', child: Text('Open')),
                            DropdownMenuItem(value: 'closed', child: Text('Closed')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          ],
                          onChanged: (v) => setState(() => _filterStatus = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats Row
                    _buildStatsRow(docs),
                    const SizedBox(height: 16),
                    
                    // Pending Banner
                    if (pending.isNotEmpty) _PendingBanner(docs: pending),
                    if (pending.isNotEmpty) const SizedBox(height: 16),
                    
                    // Results count
                    Text(
                      '${filtered.length} restaurants found',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(children: [
                            const Icon(Icons.store_outlined, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'No restaurants found',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                            ),
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
                          ...filtered.map((doc) => _RestaurantRow(doc: doc)),
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

  Widget _buildStatsRow(List<QueryDocumentSnapshot> docs) {
    final total = docs.length;
    final open = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['isApproved'] == true && data['isOpen'] == true;
    }).length;
    final closed = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['isApproved'] == true && data['isOpen'] == false;
    }).length;
    final pending = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['isApproved'] == false;
    }).length;

    return Row(
      children: [
        _buildStatChip('Total', total.toString(), AppColors.textPrimary),
        const SizedBox(width: 12),
        _buildStatChip('Open', open.toString(), AppColors.statusDelivered),
        const SizedBox(width: 12),
        _buildStatChip('Closed', closed.toString(), AppColors.textSecondary),
        const SizedBox(width: 12),
        _buildStatChip('Pending', pending.toString(), AppColors.warning),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
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
    batch.update(FirebaseFirestore.instance.collection('restaurants').doc(widget.doc.id), {
      'isApproved': !isApproved,
      'isOpen': !isApproved,
      'status': !isApproved ? 'active' : 'pendingApproval',
    });
    batch.update(FirebaseFirestore.instance.collection('users').doc(widget.doc.id), {'status': !isApproved ? 'approved' : 'rejected'});
    await batch.commit();
  }

  Future<void> _toggleOpenClose(bool isOpen) async {
    await FirebaseFirestore.instance.collection('restaurants').doc(widget.doc.id).update({
      'isOpen': !isOpen,
      'status': !isOpen ? 'active' : 'disabled',
    });
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
    final isOpen = d['isOpen'] as bool? ?? false;
    final commission = ((d['commission'] as num?) ?? 10).toDouble();
    final wallet = ((d['wallet'] as num?) ?? 0).toDouble();

    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (!isApproved) {
      statusColor = AppColors.warning;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    } else if (isOpen) {
      statusColor = AppColors.statusDelivered;
      statusText = 'Open';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppColors.textSecondary;
      statusText = 'Closed';
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        // Restaurant Info
        Expanded(flex: 4, child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurantId: widget.doc.id),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(children: [
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
            ]),
          ),
        )),
        
        // Status with Toggle
        Expanded(flex: 2, child: isApproved
          ? Row(
              children: [
                Switch(
                  value: isOpen,
                  onChanged: (_) => _toggleOpenClose(isOpen),
                  activeColor: AppColors.statusDelivered,
                ),
                Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                ],
              ),
            )),
        
        // Commission
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
        
        // Wallet
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rs.${wallet.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: wallet > 0 ? AppColors.primary : AppColors.textHint)),
          const Text('Wallet', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
        
        // Actions
        Expanded(flex: 3, child: Wrap(spacing: 6, runSpacing: 4, children: [
          _Btn(
            label: 'View',
            color: AppColors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(restaurantId: widget.doc.id),
              ),
            ),
          ),
          _Btn(
            label: isApproved ? 'Disable' : 'Approve',
            color: isApproved ? AppColors.error : AppColors.primary,
            onTap: () => _toggleStatus(isApproved),
          ),
          if (wallet > 0)
            _Btn(label: 'Release', color: AppColors.statusDelivered, onTap: () => _releasePayout(wallet)),
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
