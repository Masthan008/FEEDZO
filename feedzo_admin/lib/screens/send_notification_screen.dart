import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../widgets/topbar.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(
          title: 'Send Notification',
          subtitle: 'Push notifications via OneSignal',
        ),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Send to User'),
              Tab(text: 'Broadcast by Role'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [_SendToUserTab(), _BroadcastTab()],
          ),
        ),
      ],
    );
  }
}

// ─── Send to specific user ────────────────────────────────────────────────────

class _SendToUserTab extends StatefulWidget {
  const _SendToUserTab();

  @override
  State<_SendToUserTab> createState() => _SendToUserTabState();
}

class _SendToUserTabState extends State<_SendToUserTab> {
  final _uidCtrl = TextEditingController();
  final _titleCtrl = TextEditingController(text: 'Test from Admin');
  final _bodyCtrl = TextEditingController(
    text: 'Hello! This is a test notification.',
  );
  bool _loading = false;
  String? _result;
  bool _success = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_uidCtrl.text.trim().isEmpty) {
      setState(() {
        _result = 'Enter a Firebase UID';
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final res = await OneSignalApi.sendToUser(
        userId: _uidCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      );
      setState(() {
        _success = res;
        _result = res
            ? '✅ Notification sent successfully!'
            : '❌ Failed to send. Check UID and OneSignal setup.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _success = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Target User',
            subtitle: 'Enter the Firebase UID of the user to notify',
            child: Column(
              children: [
                TextField(
                  controller: _uidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Firebase UID',
                    hintText: 'e.g. abc123xyz...',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notification Content',
            subtitle: 'What the user will see',
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    prefixIcon: Icon(Icons.message_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _success
                    ? AppColors.statusDeliveredBg
                    : AppColors.statusCancelledBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _success ? AppColors.primary : AppColors.error,
                ),
              ),
              child: Text(
                _result!,
                style: TextStyle(
                  color: _success ? AppColors.primary : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _send,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_loading ? 'Sending...' : 'Send Notification'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Broadcast by role ────────────────────────────────────────────────────────

class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  String _selectedRole = 'customer';
  final _titleCtrl = TextEditingController(text: 'Announcement');
  final _bodyCtrl = TextEditingController(
    text: 'Important update from Feedzo admin.',
  );
  bool _loading = false;
  String? _result;
  bool _success = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final res = await OneSignalApi.broadcastByRole(
        role: _selectedRole,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      );
      setState(() {
        _success = res;
        _result = res
            ? '✅ Broadcast sent to all ${_selectedRole}s!'
            : '❌ Failed to broadcast. Check OneSignal setup.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _success = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Target Role',
            subtitle: 'Send to all users with this role',
            child: Column(
              children: [
                _RoleChip(
                  label: 'All Customers',
                  role: 'customer',
                  selected: _selectedRole,
                  onTap: (r) => setState(() => _selectedRole = r),
                ),
                const SizedBox(height: 8),
                _RoleChip(
                  label: 'All Restaurants',
                  role: 'restaurant',
                  selected: _selectedRole,
                  onTap: (r) => setState(() => _selectedRole = r),
                ),
                const SizedBox(height: 8),
                _RoleChip(
                  label: 'All Drivers',
                  role: 'driver',
                  selected: _selectedRole,
                  onTap: (r) => setState(() => _selectedRole = r),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Notification Content',
            subtitle: 'What users will see',
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    prefixIcon: Icon(Icons.message_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _success
                    ? AppColors.statusDeliveredBg
                    : AppColors.statusCancelledBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _success ? AppColors.primary : AppColors.error,
                ),
              ),
              child: Text(
                _result!,
                style: TextStyle(
                  color: _success ? AppColors.primary : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _broadcast,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.campaign_rounded, size: 18),
              label: Text(
                _loading
                    ? 'Broadcasting...'
                    : 'Broadcast to All ${_selectedRole.capitalize()}s',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OneSignal REST API helper ────────────────────────────────────────────────

class OneSignalApi {
  static const _appId = '90f7c5c6-b51f-466a-acdb-a4829b419363';
  static const _apiKey =
      'os_v2_app_sd34lrvvd5dgvlg3usbjwqmtmnkyn3llzrou5amwfr35ndpvxhxqxagknlesssypciia4ds5chlbmggfvji74wc5cuu3dtfgdftcnnq';

  static Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final res = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_apiKey',
      },
      body: jsonEncode({
        'app_id': _appId,
        'include_external_user_ids': [userId],
        'headings': {'en': title},
        'contents': {'en': body},
        'data': ?data,
      }),
    );
    return res.statusCode == 200;
  }

  static Future<bool> broadcastByRole({
    required String role,
    required String title,
    required String body,
  }) async {
    final res = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_apiKey',
      },
      body: jsonEncode({
        'app_id': _appId,
        'filters': [
          {'field': 'tag', 'key': 'role', 'relation': '=', 'value': role},
        ],
        'headings': {'en': title},
        'contents': {'en': body},
      }),
    );
    return res.statusCode == 200;
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String role;
  final String selected;
  final ValueChanged<String> onTap;
  const _RoleChip({
    required this.label,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = role == selected;
    return GestureDetector(
      onTap: () => onTap(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              role == 'customer'
                  ? Icons.person_rounded
                  : role == 'restaurant'
                  ? Icons.store_rounded
                  : Icons.delivery_dining_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
