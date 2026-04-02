import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../providers/admin_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/topbar.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    final orderAlerts = ap.alerts.where((a) => a.type == AlertType.orderAlert).toList();
    final loginAlerts = ap.alerts.where((a) => a.type == AlertType.loginActivity).toList();
    final systemAlerts = ap.alerts.where((a) => a.type == AlertType.systemEvent).toList();

    return Column(
      children: [
        TopBar(title: 'Alerts', subtitle: '${ap.unreadAlerts} unread'),
        Container(
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'All (${ap.alerts.length})'),
                    Tab(text: 'Orders (${orderAlerts.length})'),
                    Tab(text: 'Logins (${loginAlerts.length})'),
                    Tab(text: 'System (${systemAlerts.length})'),
                  ],
                ),
              ),
              if (ap.unreadAlerts > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: ap.markAllAlertsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark all read'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _AlertList(alerts: ap.alerts, ap: ap),
              _AlertList(alerts: orderAlerts, ap: ap),
              _AlertList(alerts: loginAlerts, ap: ap),
              _AlertList(alerts: systemAlerts, ap: ap),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertList extends StatelessWidget {
  final List<AdminAlert> alerts;
  final AdminProvider ap;
  const _AlertList({required this.alerts, required this.ap});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Center(child: Text('No alerts in this category', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: alerts.length,
      itemBuilder: (_, i) => _AlertCard(alert: alerts[i], ap: ap),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AdminAlert alert;
  final AdminProvider ap;
  const _AlertCard({required this.alert, required this.ap});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.high: return AppColors.error;
      case AlertSeverity.medium: return AppColors.warning;
      case AlertSeverity.low: return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.orderAlert: return Icons.receipt_long_rounded;
      case AlertType.loginActivity: return Icons.login_rounded;
      case AlertType.systemEvent: return Icons.settings_rounded;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case AlertType.orderAlert: return 'Order Alert';
      case AlertType.loginActivity: return 'Login Activity';
      case AlertType.systemEvent: return 'System Event';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert.isRead ? AppColors.surface : _color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.isRead ? AppColors.border : _color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_typeIcon, color: _color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(alert.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: alert.isRead ? AppColors.textSecondary : AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          AlertSeverityBadge(severity: alert.severity),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                            child: Text(_typeLabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          ),
                          if (!alert.isRead) ...[
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(alert.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_timeAgo(alert.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    if (!alert.isRead) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => ap.markAlertRead(alert.id),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Detail rows for order alerts
          if (alert.type == AlertType.orderAlert && (alert.orderId != null || alert.customerName != null))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (alert.orderId != null) _DetailChip(icon: Icons.tag_rounded, label: 'Order', value: '#${alert.orderId}'),
                  if (alert.customerName != null) _DetailChip(icon: Icons.person_rounded, label: 'Customer', value: alert.customerName!),
                  if (alert.restaurantName != null) _DetailChip(icon: Icons.store_rounded, label: 'Restaurant', value: alert.restaurantName!),
                  if (alert.orderedItems != null && alert.orderedItems!.isNotEmpty)
                    _DetailChip(icon: Icons.fastfood_rounded, label: 'Items', value: alert.orderedItems!.join(', ')),
                ],
              ),
            ),
          // Login activity detail
          if (alert.type == AlertType.loginActivity)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (alert.customerName != null) _DetailChip(icon: Icons.person_rounded, label: 'User', value: alert.customerName!),
                  if (alert.restaurantName != null) _DetailChip(icon: Icons.store_rounded, label: 'Restaurant', value: alert.restaurantName!),
                  _DetailChip(icon: Icons.access_time_rounded, label: 'Time', value: _formatTime(alert.createdAt)),
                ],
              ),
            ),
          // System event detail
          if (alert.type == AlertType.systemEvent && (alert.orderId != null || alert.restaurantName != null))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (alert.orderId != null) _DetailChip(icon: Icons.tag_rounded, label: 'Order', value: '#${alert.orderId}'),
                  if (alert.restaurantName != null) _DetailChip(icon: Icons.store_rounded, label: 'Restaurant', value: alert.restaurantName!),
                  _DetailChip(icon: Icons.access_time_rounded, label: 'Time', value: _formatTime(alert.createdAt)),
                ],
              ),
            ),
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
