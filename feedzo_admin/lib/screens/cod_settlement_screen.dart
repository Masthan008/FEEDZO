import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../providers/admin_provider.dart';
import '../widgets/topbar.dart';

class CodSettlementScreen extends StatefulWidget {
  const CodSettlementScreen({super.key});

  @override
  State<CodSettlementScreen> createState() => _CodSettlementScreenState();
}

class _CodSettlementScreenState extends State<CodSettlementScreen> {
  String? _selectedDriverId;

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    final selected = _selectedDriverId != null
        ? ap.driverSummaries.firstWhere((s) => s.driverId == _selectedDriverId, orElse: () => ap.driverSummaries.first)
        : null;
    final selectedDriver = _selectedDriverId != null
        ? ap.drivers.firstWhere((d) => d.id == _selectedDriverId, orElse: () => ap.drivers.first)
        : null;

    return Column(
      children: [
        const TopBar(title: 'COD & Settlement', subtitle: 'Driver cash-on-delivery tracking and settlement'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCards(ap: ap),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _DriverListTable(ap: ap, selectedId: _selectedDriverId, onSelect: (id) => setState(() => _selectedDriverId = id))),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: selected != null && selectedDriver != null
                        ? _DriverDetailPanel(summary: selected, driver: selectedDriver, ap: ap)
                        : _EmptyDetail()),
                  ],
                ),
                if (_selectedDriverId != null && selected != null) ...[
                  const SizedBox(height: 24),
                  _SettlementHistory(driverId: _selectedDriverId!, driver: selectedDriver!, ap: ap),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final AdminProvider ap;
  const _SummaryCards({required this.ap});

  @override
  Widget build(BuildContext context) {
    final totalCod = ap.driverSummaries.fold<double>(0, (s, d) => s + d.codAmount);
    final totalSubmitted = ap.driverSummaries.fold<double>(0, (s, d) => s + d.submittedAmount);
    final totalPending = ap.totalPendingCash;
    final settled = ap.driverSummaries.where((d) => d.settlementStatus == SettlementStatus.settled).length;

    return Row(
      children: [
        _Card(icon: Icons.payments_rounded, label: 'Total COD Today', value: '₹${totalCod.toStringAsFixed(0)}', color: AppColors.primary, sub: '${ap.driverSummaries.fold(0, (s, d) => s + d.codOrders)} COD orders'),
        const SizedBox(width: 16),
        _Card(icon: Icons.check_circle_rounded, label: 'Submitted to Admin', value: '₹${totalSubmitted.toStringAsFixed(0)}', color: AppColors.statusDelivered, sub: '$settled drivers fully settled'),
        const SizedBox(width: 16),
        _Card(icon: Icons.warning_rounded, label: 'Pending Collection', value: '₹${totalPending.toStringAsFixed(0)}', color: AppColors.error, sub: '${ap.driversWithPendingCash} drivers pending'),
        const SizedBox(width: 16),
        _Card(icon: Icons.wifi_rounded, label: 'Online Payments', value: '₹${ap.driverSummaries.fold<double>(0, (s, d) => s + d.onlineAmount).toStringAsFixed(0)}', color: AppColors.info, sub: '${ap.driverSummaries.fold(0, (s, d) => s + d.onlineOrders)} online orders'),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String sub;
  const _Card({required this.icon, required this.label, required this.value, required this.color, required this.sub});

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
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Driver List Table ────────────────────────────────────────────────────────

class _DriverListTable extends StatelessWidget {
  final AdminProvider ap;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _DriverListTable({required this.ap, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Driver Daily Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF9FAFB),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('COD Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
          ),
          ...ap.driverSummaries.map((s) {
            final driver = ap.drivers.firstWhere((d) => d.id == s.driverId, orElse: () => ap.drivers.first);
            final isSelected = selectedId == s.driverId;
            return GestureDetector(
              onTap: () => onSelect(s.driverId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySurface : null,
                  border: Border(
                    bottom: const BorderSide(color: AppColors.border),
                    left: isSelected ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 16, backgroundColor: AppColors.primarySurface, child: Text(driver.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driver.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text(driver.vehicle.split('·').first.trim(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                            ],
                          )),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.totalOrders}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${s.codOrders} COD · ${s.onlineOrders} online', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    )),
                    Expanded(flex: 2, child: Text('₹${s.codAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s.pendingAmount > 0 ? '₹${s.pendingAmount.toStringAsFixed(0)}' : '—',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: s.pendingAmount > 0 ? AppColors.error : AppColors.textHint),
                      ),
                    ),
                    Expanded(flex: 2, child: _SettlementBadge(status: s.settlementStatus)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Driver Detail Panel ──────────────────────────────────────────────────────

class _DriverDetailPanel extends StatefulWidget {
  final DriverDailySummary summary;
  final Driver driver;
  final AdminProvider ap;
  const _DriverDetailPanel({required this.summary, required this.driver, required this.ap});

  @override
  State<_DriverDetailPanel> createState() => _DriverDetailPanelState();
}

class _DriverDetailPanelState extends State<_DriverDetailPanel> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final val = double.tryParse(_amountCtrl.text);
    if (val == null || val <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (val > widget.summary.pendingAmount + 0.01) {
      setState(() => _error = 'Amount exceeds pending balance');
      return;
    }
    setState(() => _error = null);
    widget.ap.recordCashSubmission(widget.driver.id, val, _noteCtrl.text.trim());
    _amountCtrl.clear();
    _noteCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹${val.toStringAsFixed(0)} marked as received from ${widget.driver.name}'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final isPending = s.pendingAmount > 0;

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: AppColors.primarySurface, child: Text(widget.driver.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.driver.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(widget.driver.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _SettlementBadge(status: s.settlementStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                Row(
                  children: [
                    _StatBox(label: 'Total Orders', value: '${s.totalOrders}', icon: Icons.receipt_long_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    _StatBox(label: 'COD Orders', value: '${s.codOrders}', icon: Icons.money_rounded, color: AppColors.warning),
                    const SizedBox(width: 10),
                    _StatBox(label: 'Online Orders', value: '${s.onlineOrders}', icon: Icons.wifi_rounded, color: AppColors.info),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _BreakdownRow(label: 'COD Amount Collected', value: '₹${s.codAmount.toStringAsFixed(0)}', color: AppColors.textPrimary),
                      const SizedBox(height: 8),
                      _BreakdownRow(label: 'Online Payment Amount', value: '₹${s.onlineAmount.toStringAsFixed(0)}', color: AppColors.info),
                      const Divider(height: 20, color: AppColors.border),
                      _BreakdownRow(label: 'Submitted to Admin', value: '₹${s.submittedAmount.toStringAsFixed(0)}', color: AppColors.statusDelivered, bold: true),
                      const SizedBox(height: 6),
                      _BreakdownRow(
                        label: 'Remaining Pending',
                        value: '₹${s.pendingAmount.toStringAsFixed(0)}',
                        color: isPending ? AppColors.error : AppColors.textHint,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Cash submission form
                if (isPending) ...[
                  const Text('Mark Cash as Received', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Pending: ₹${s.pendingAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Amount received',
                            prefixText: '₹ ',
                            suffixIcon: TextButton(
                              onPressed: () => _amountCtrl.text = s.pendingAmount.toStringAsFixed(0),
                              child: const Text('Full', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(hintText: 'Note (optional)', prefixIcon: Icon(Icons.note_rounded, size: 16, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Mark as Received'),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.statusDeliveredBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Fully Settled', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                // Submission log
                if (s.submissions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Submission Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...s.submissions.reversed.map((sub) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${sub.amount.toStringAsFixed(0)} received', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              if (sub.note.isNotEmpty) Text(sub.note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(_formatTime(sub.submittedAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Settlement History Table ─────────────────────────────────────────────────

class _SettlementHistory extends StatelessWidget {
  final String driverId;
  final Driver driver;
  final AdminProvider ap;
  const _SettlementHistory({required this.driverId, required this.driver, required this.ap});

  @override
  Widget build(BuildContext context) {
    final records = ap.settlementHistory[driverId] ?? [];

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Settlement History — ${driver.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF9FAFB),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Orders Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('COD Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Submitted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
            ),
          ),
          if (records.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No history available', style: TextStyle(color: AppColors.textSecondary)))
          else
            ...records.map((r) {
              final pending = r.pending;
              final status = pending <= 0 ? SettlementStatus.settled : (r.submittedAmount > 0 ? SettlementStatus.partial : SettlementStatus.pending);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(_formatDate(r.date), style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text('${r.ordersCompleted}', style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text('₹${r.codCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 2, child: Text('₹${r.submittedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppColors.statusDelivered, fontWeight: FontWeight.w500))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        pending > 0 ? '₹${pending.toStringAsFixed(0)}' : '—',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pending > 0 ? AppColors.error : AppColors.textHint),
                      ),
                    ),
                    Expanded(flex: 2, child: _SettlementBadge(status: status)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final isToday = _isSameDay(dt, DateTime.now());
    if (isToday) return 'Today';
    final isYesterday = _isSameDay(dt, DateTime.now().subtract(const Duration(days: 1)));
    if (isYesterday) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 40, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('Select a driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Click any row to view details\nand manage cash settlement', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SettlementBadge extends StatelessWidget {
  final SettlementStatus status;
  const _SettlementBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case SettlementStatus.settled:
        color = AppColors.statusDelivered; bg = AppColors.statusDeliveredBg; label = 'Settled';
      case SettlementStatus.partial:
        color = AppColors.warning; bg = AppColors.statusPendingBg; label = 'Partial';
      case SettlementStatus.pending:
        color = AppColors.error; bg = AppColors.statusCancelledBg; label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _BreakdownRow({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
