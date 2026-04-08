import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../providers/admin_provider.dart';

class TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const TopBar({super.key, required this.title, this.subtitle, this.onBack, this.actions});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (actions != null) ...[
            ...actions!,
            const SizedBox(width: 16),
          ],
          Container(
            width: 220, height: 36,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: const Row(
              children: [
                SizedBox(width: 10),
                Icon(Icons.search_rounded, size: 16, color: AppColors.textHint),
                SizedBox(width: 8),
                Text('Search...', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _NotificationBell(ap: ap),
          const SizedBox(width: 8),
          _AdminAvatar(email: ap.adminEmail),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatefulWidget {
  final AdminProvider ap;
  const _NotificationBell({required this.ap});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  void _toggle() {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
    } else {
      _overlay = _buildOverlay();
      Overlay.of(context).insert(_overlay!);
    }
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              offset: const Offset(-280, 48),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: _NotificationDropdown(ap: widget.ap, onClose: _close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.ap.unreadAlerts;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: _toggle,
          ),
          if (count > 0)
            Positioned(
              right: 8, top: 8,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationDropdown extends StatelessWidget {
  final AdminProvider ap;
  final VoidCallback onClose;
  const _NotificationDropdown({required this.ap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final recent = ap.alerts.take(6).toList();
    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (ap.unreadAlerts > 0)
                  TextButton(
                    onPressed: () { ap.markAllAlertsRead(); onClose(); },
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final a = recent[i];
                return _NotifItem(alert: a, onTap: () { ap.markAlertRead(a.id); onClose(); });
              },
            ),
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No notifications', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final AdminAlert alert;
  final VoidCallback onTap;
  const _NotifItem({required this.alert, required this.onTap});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.high: return AppColors.error;
      case AlertSeverity.medium: return AppColors.warning;
      case AlertSeverity.low: return AppColors.info;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case AlertType.orderAlert: return Icons.receipt_long_rounded;
      case AlertType.loginActivity: return Icons.login_rounded;
      case AlertType.systemEvent: return Icons.settings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: alert.isRead ? Colors.transparent : _color.withValues(alpha: 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(_icon, color: _color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: TextStyle(fontSize: 13, fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(alert.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_timeAgo(alert.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ),
            if (!alert.isRead)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          ],
        ),
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

class _AdminAvatar extends StatelessWidget {
  final String email;
  const _AdminAvatar({required this.email});

  String _initials(String name) {
    if (name.isEmpty) return 'A';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    final name = ap.adminName;
    return PopupMenuButton(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Text(_initials(name), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      itemBuilder: (_) => <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Admin' : name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                ap.adminEmail.isEmpty ? email : ap.adminEmail,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
        onTap: () async {
          await context.read<AdminProvider>().logoutFirebase();
        },
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
