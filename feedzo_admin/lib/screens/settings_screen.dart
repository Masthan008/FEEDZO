import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';
import '../widgets/topbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    return Column(
      children: [
        const TopBar(
          title: 'Settings',
          subtitle: 'System configuration and feature toggles',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(
                  title: 'Payment Features',
                  subtitle:
                      'Enable or disable payment-related features across the platform',
                  children: [
                    _ToggleTile(
                      icon: Icons.money_rounded,
                      color: AppColors.warning,
                      title: 'Cash on Delivery (COD)',
                      subtitle:
                          'Allow customers to pay cash at delivery. Disabling hides COD options across all apps.',
                      value: ap.settings.codEnabled,
                      onChanged: (v) => ap.updateSettings(codEnabled: v),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _ToggleTile(
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.info,
                      title: 'Driver Settlement Tracking',
                      subtitle:
                          'Track COD cash collected by drivers and manage settlements. Disabling hides the COD & Settlement page.',
                      value: ap.settings.driverSettlementEnabled,
                      onChanged: (v) =>
                          ap.updateSettings(driverSettlementEnabled: v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Payment Flow',
                  subtitle: 'How payments are processed on the platform',
                  children: [
                    _InfoTile(
                      icon: Icons.wifi_rounded,
                      color: AppColors.primary,
                      title: 'Online Payment',
                      lines: [
                        'Customer pays online at checkout',
                        'Full amount goes to Admin',
                        'Commission deducted automatically',
                        'Restaurant share credited to wallet',
                      ],
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoTile(
                      icon: Icons.money_rounded,
                      color: AppColors.warning,
                      title: 'Cash on Delivery (COD)',
                      lines: [
                        'Customer pays cash to driver on delivery',
                        'Driver collects and holds the cash',
                        'Driver submits cash to Admin',
                        'Admin settles restaurant share from collected cash',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'Commission Logic',
                  subtitle: 'How commission is calculated per order',
                  children: [
                    _InfoTile(
                      icon: Icons.calculate_rounded,
                      color: const Color(0xFF7C3AED),
                      title: 'Commission Calculation Example',
                      lines: [
                        'Order Total: Rs.10,000',
                        'Commission Rate: 10%',
                        'Admin Commission: Rs.1,000',
                        'Restaurant Earnings: Rs.9,000',
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
              ),
              Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: value ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...lines.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
