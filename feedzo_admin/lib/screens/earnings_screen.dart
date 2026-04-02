import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../providers/admin_provider.dart';
import '../widgets/topbar.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _rateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rate = context.read<AdminProvider>().commissionRate;
    _rateCtrl.text = (rate * 100).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _tab.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    return Column(
      children: [
        const TopBar(title: 'Earnings & Commission', subtitle: 'Platform revenue and payout management'),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Overview'), Tab(text: 'Order Breakdown'), Tab(text: 'Payouts')],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _OverviewTab(ap: ap, rateCtrl: _rateCtrl),
              _OrderBreakdownTab(ap: ap),
              _PayoutsTab(ap: ap),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final AdminProvider ap;
  final TextEditingController rateCtrl;
  const _OverviewTab({required this.ap, required this.rateCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _EarningCard(title: 'Total Revenue', value: '₹${ap.totalRevenue.toStringAsFixed(0)}', subtitle: 'From delivered orders', icon: Icons.account_balance_rounded, color: AppColors.primary),
              const SizedBox(width: 16),
              _EarningCard(title: 'Commission Earned', value: '₹${ap.totalCommission.toStringAsFixed(0)}', subtitle: '${(ap.commissionRate * 100).toInt()}% of revenue', icon: Icons.percent_rounded, color: AppColors.info),
              const SizedBox(width: 16),
              _EarningCard(title: 'Restaurant Payouts', value: '₹${(ap.totalRevenue - ap.totalCommission).toStringAsFixed(0)}', subtitle: 'Distributed to restaurants', icon: Icons.store_rounded, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 16),
              _EarningCard(title: 'Pending Payouts', value: '₹${ap.restaurants.fold<double>(0, (s, r) => s + r.walletBalance).toStringAsFixed(0)}', subtitle: 'In restaurant wallets', icon: Icons.pending_rounded, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _CommissionSettings(ap: ap, rateCtrl: rateCtrl)),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _LiveActivityFeed(ap: ap)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommissionSettings extends StatelessWidget {
  final AdminProvider ap;
  final TextEditingController rateCtrl;
  const _CommissionSettings({required this.ap, required this.rateCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Commission Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Global platform commission rate', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.percent_rounded, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(ap.commissionRate * 100).toInt()}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text('Current Rate', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'New Rate (%)', suffixText: '%'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(rateCtrl.text);
                  if (val != null && val > 0 && val <= 50) {
                    ap.setCommissionRate(val / 100);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rate updated to ${val.toInt()}%'), backgroundColor: AppColors.primary));
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('How it works', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          _FlowStep(step: '1', label: 'Customer pays full order amount'),
          _FlowStep(step: '2', label: 'Platform collects ${(ap.commissionRate * 100).toInt()}% commission'),
          _FlowStep(step: '3', label: 'Remaining ${(100 - ap.commissionRate * 100).toInt()}% goes to restaurant wallet'),
          _FlowStep(step: '4', label: 'Admin releases payout to restaurant'),
        ],
      ),
    );
  }
}

class _LiveActivityFeed extends StatelessWidget {
  final AdminProvider ap;
  const _LiveActivityFeed({required this.ap});

  IconData _activityIcon(ActivityType t) {
    if (t == ActivityType.orderPlaced) return Icons.add_shopping_cart_rounded;
    if (t == ActivityType.driverAssigned) return Icons.delivery_dining_rounded;
    if (t == ActivityType.orderDelivered) return Icons.check_circle_rounded;
    if (t == ActivityType.orderDelayed) return Icons.warning_rounded;
    if (t == ActivityType.paymentReleased) return Icons.payments_rounded;
    if (t == ActivityType.cashSubmitted) return Icons.account_balance_wallet_rounded;
    if (t == ActivityType.loginRestaurant) return Icons.store_rounded;
    if (t == ActivityType.loginDriver) return Icons.delivery_dining_rounded;
    return Icons.person_rounded;
  }

  Color _activityColor(ActivityType t) {
    if (t == ActivityType.orderPlaced) return AppColors.primary;
    if (t == ActivityType.driverAssigned) return AppColors.info;
    if (t == ActivityType.orderDelivered) return AppColors.statusDelivered;
    if (t == ActivityType.orderDelayed) return AppColors.error;
    if (t == ActivityType.paymentReleased) return const Color(0xFF7C3AED);
    if (t == ActivityType.cashSubmitted) return const Color(0xFF0891B2);
    if (t == ActivityType.loginRestaurant) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Live Activity Feed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...ap.activityFeed.take(10).map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _activityColor(item.type).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_activityIcon(item.type), color: _activityColor(item.type), size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.message, style: const TextStyle(fontSize: 13))),
                Text(_timeAgo(item.time), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Order Breakdown Tab ──────────────────────────────────────────────────────

class _OrderBreakdownTab extends StatelessWidget {
  final AdminProvider ap;
  const _OrderBreakdownTab({required this.ap});

  @override
  Widget build(BuildContext context) {
    final orders = ap.orders.where((o) =>
      o.status == OrderStatus.delivered ||
      o.status == OrderStatus.outForDelivery ||
      o.status == OrderStatus.preparing).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB), borderRadius: BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: AppColors.border))),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 3, child: Text('Restaurant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Order Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Share %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Commission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Restaurant Share', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                ],
              ),
            ),
            ...orders.map((o) => _OrderCommissionRow(order: o, ap: ap)),
          ],
        ),
      ),
    );
  }
}

class _OrderCommissionRow extends StatefulWidget {
  final AdminOrder order;
  final AdminProvider ap;
  const _OrderCommissionRow({required this.order, required this.ap});

  @override
  State<_OrderCommissionRow> createState() => _OrderCommissionRowState();
}

class _OrderCommissionRowState extends State<_OrderCommissionRow> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: (widget.order.commissionRate * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('#${o.id}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(o.restaurantName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('₹${o.orderValue.toInt()}', style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 2,
            child: _editing
                ? Row(children: [
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final val = double.tryParse(_ctrl.text);
                        if (val != null && val > 0 && val <= 50) widget.ap.updateOrderCommission(o.id, val / 100);
                        setState(() => _editing = false);
                      },
                      child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
                    ),
                  ])
                : GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Row(children: [
                      Text('${(o.commissionRate * 100).toInt()}%', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.textHint),
                    ]),
                  ),
          ),
          Expanded(flex: 2, child: Text('₹${o.commission.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('₹${o.restaurantPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 2,
            child: o.status == OrderStatus.delivered
                ? o.paymentReleased
                    ? const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14), SizedBox(width: 4), Text('Released', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500))])
                    : GestureDetector(
                        onTap: () => widget.ap.releaseOrderPayment(o.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                          child: const Text('Release', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      )
                : Text(o.statusLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ─── Payouts Tab ──────────────────────────────────────────────────────────────

class _PayoutsTab extends StatelessWidget {
  final AdminProvider ap;
  const _PayoutsTab({required this.ap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: ap.restaurants.map((r) => _RestaurantPayoutCard(restaurant: r, ap: ap)).toList()),
    );
  }
}

class _RestaurantPayoutCard extends StatefulWidget {
  final AdminRestaurant restaurant;
  final AdminProvider ap;
  const _RestaurantPayoutCard({required this.restaurant, required this.ap});

  @override
  State<_RestaurantPayoutCard> createState() => _RestaurantPayoutCardState();
}

class _RestaurantPayoutCardState extends State<_RestaurantPayoutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: AppColors.primarySurface, child: Text(r.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(r.cuisine, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${r.walletBalance.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: r.walletBalance > 0 ? AppColors.primary : AppColors.textHint)),
                  const Text('Wallet Balance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                const SizedBox(width: 16),
                r.walletBalance > 0
                    ? ElevatedButton.icon(
                        onPressed: () => widget.ap.releasePayout(r.id),
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: Text('Release ₹${r.walletBalance.toStringAsFixed(0)}'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                        child: const Text('No pending payout', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      ),
                const SizedBox(width: 8),
                if (r.transactions.isNotEmpty)
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
              ],
            ),
          ),
          if (_expanded && r.transactions.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFF9FAFB),
              child: const Row(children: [
                Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Commission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Paid Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ]),
            ),
            ...r.transactions.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                Expanded(flex: 2, child: Text('#${t.orderId}', style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                Expanded(flex: 2, child: Text('₹${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 2, child: Text(t.commission > 0 ? '₹${t.commission.toStringAsFixed(0)}' : '-', style: const TextStyle(fontSize: 13, color: AppColors.info))),
                Expanded(flex: 2, child: Text('₹${(t.amount - t.commission).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: t.type == TransactionType.payout ? AppColors.primarySurface : const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
                  child: Text(t.type == TransactionType.payout ? 'Payout' : 'Commission', style: TextStyle(fontSize: 11, color: t.type == TransactionType.payout ? AppColors.primary : AppColors.info, fontWeight: FontWeight.w600)),
                )),
                Expanded(flex: 2, child: Text('${t.date.day}/${t.date.month} ${t.date.hour.toString().padLeft(2,'0')}:${t.date.minute.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              ]),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EarningCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _EarningCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 14),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String step;
  final String label;
  const _FlowStep({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
