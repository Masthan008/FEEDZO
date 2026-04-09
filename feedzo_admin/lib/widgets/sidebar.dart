import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';

enum AdminPage { dashboard, orders, restaurants, drivers, users, earnings, coupons, banners, refunds, incentives, recommended, aiInsights, alerts, codSettlement, settings, sendNotification, hikeCharges, driverPayouts, reviews, zones, cuisines, foodAddons, subscriptions, customerWallet, restaurantWithdrawals, languageSettings, themeSettings, emailTemplates, socialMedia, legalPages, aboutUs, chatSystem, newsletter, appVersion, landingPage, tips, verification, thirdPartyConfig, bulkImportExport, databaseCleanup, driverEarnings, cashLimit, foodReviews, reports, dispatchManagement, vehicleCoverage, businessModels, selfRegistration, subscriptionReports, campaignReports, customerAnalytics, restaurantAnalytics, driverAnalytics, inventoryManagement, loyaltyProgram, referralProgram, promotions, scheduleManagement, paymentMethods, deliveryZones, orderAnalytics, supportTickets, notifications, auditLogs, feedback, userActivity, systemHealth, apiLogs, performanceMonitor }

class Sidebar extends StatelessWidget {
  final AdminPage current;
  final ValueChanged<AdminPage> onSelect;
  const Sidebar({super.key, required this.current, required this.onSelect});

  String _initials(String name) {
    if (name.isEmpty) return 'A';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    final alertCount = ap.unreadAlerts;

    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20)),
                const SizedBox(width: 10),
                const Text('Feedzo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)), child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('MAIN MENU', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.dashboard_rounded, label: 'Dashboard', page: AdminPage.dashboard, current: current, onTap: onSelect),
                  _Item(icon: Icons.receipt_long_rounded, label: 'Orders', page: AdminPage.orders, current: current, onTap: onSelect),
                  _Item(icon: Icons.store_rounded, label: 'Restaurants', page: AdminPage.restaurants, current: current, onTap: onSelect),
                  _Item(icon: Icons.delivery_dining_rounded, label: 'Drivers', page: AdminPage.drivers, current: current, onTap: onSelect),
                  _Item(icon: Icons.people_rounded, label: 'Users', page: AdminPage.users, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('ANALYTICS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.currency_rupee_rounded, label: 'Earnings', page: AdminPage.earnings, current: current, onTap: onSelect),
                  _Item(icon: Icons.local_offer_rounded, label: 'Coupons', page: AdminPage.coupons, current: current, onTap: onSelect),
                  _Item(icon: Icons.view_carousel_rounded, label: 'Banners', page: AdminPage.banners, current: current, onTap: onSelect),
                  _Item(icon: Icons.currency_exchange_rounded, label: 'Refunds', page: AdminPage.refunds, current: current, onTap: onSelect),
                  _Item(icon: Icons.emoji_events_rounded, label: 'Incentives', page: AdminPage.incentives, current: current, onTap: onSelect),
                  _Item(icon: Icons.thumb_up_rounded, label: 'Recommended', page: AdminPage.recommended, current: current, onTap: onSelect),
                  if (ap.settings.driverSettlementEnabled)
                    _Item(icon: Icons.account_balance_wallet_rounded, label: 'COD & Settlement', page: AdminPage.codSettlement, current: current, onTap: onSelect, badge: ap.driversWithPendingCash > 0 ? ap.driversWithPendingCash : null),
                  _Item(icon: Icons.price_change_rounded, label: 'Hike Charges', page: AdminPage.hikeCharges, current: current, onTap: onSelect),
                  _Item(icon: Icons.account_balance_wallet_rounded, label: 'Driver Payouts', page: AdminPage.driverPayouts, current: current, onTap: onSelect),
                  _Item(icon: Icons.auto_awesome_rounded, label: 'AI Insights', page: AdminPage.aiInsights, current: current, onTap: onSelect),
                  _Item(icon: Icons.rate_review_rounded, label: 'Reviews', page: AdminPage.reviews, current: current, onTap: onSelect),
                  _Item(icon: Icons.notifications_rounded, label: 'Alerts', page: AdminPage.alerts, current: current, onTap: onSelect, badge: alertCount > 0 ? alertCount : null),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('MANAGEMENT', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.location_city_rounded, label: 'Zones', page: AdminPage.zones, current: current, onTap: onSelect),
                  _Item(icon: Icons.restaurant_menu_rounded, label: 'Cuisines', page: AdminPage.cuisines, current: current, onTap: onSelect),
                  _Item(icon: Icons.add_circle_outline_rounded, label: 'Food Addons', page: AdminPage.foodAddons, current: current, onTap: onSelect),
                  _Item(icon: Icons.card_membership_rounded, label: 'Subscriptions', page: AdminPage.subscriptions, current: current, onTap: onSelect),
                  _Item(icon: Icons.account_balance_wallet_rounded, label: 'Customer Wallet', page: AdminPage.customerWallet, current: current, onTap: onSelect),
                  _Item(icon: Icons.account_balance_rounded, label: 'Restaurant Withdrawals', page: AdminPage.restaurantWithdrawals, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('CONTENT', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.language_rounded, label: 'Language Settings', page: AdminPage.languageSettings, current: current, onTap: onSelect),
                  _Item(icon: Icons.palette_rounded, label: 'Theme Settings', page: AdminPage.themeSettings, current: current, onTap: onSelect),
                  _Item(icon: Icons.email_rounded, label: 'Email Templates', page: AdminPage.emailTemplates, current: current, onTap: onSelect),
                  _Item(icon: Icons.share_rounded, label: 'Social Media', page: AdminPage.socialMedia, current: current, onTap: onSelect),
                  _Item(icon: Icons.gavel_rounded, label: 'Legal Pages', page: AdminPage.legalPages, current: current, onTap: onSelect),
                  _Item(icon: Icons.info_rounded, label: 'About Us', page: AdminPage.aboutUs, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('COMMUNICATION', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.chat_bubble_rounded, label: 'Chat System', page: AdminPage.chatSystem, current: current, onTap: onSelect),
                  _Item(icon: Icons.mark_email_read_rounded, label: 'Newsletter', page: AdminPage.newsletter, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('APP CONFIG', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.system_update_rounded, label: 'App Version', page: AdminPage.appVersion, current: current, onTap: onSelect),
                  _Item(icon: Icons.web_rounded, label: 'Landing Page', page: AdminPage.landingPage, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('OPERATIONS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.attach_money_rounded, label: 'Tips', page: AdminPage.tips, current: current, onTap: onSelect),
                  _Item(icon: Icons.verified_user_rounded, label: 'Verification', page: AdminPage.verification, current: current, onTap: onSelect),
                  _Item(icon: Icons.extension_rounded, label: '3rd Party Config', page: AdminPage.thirdPartyConfig, current: current, onTap: onSelect),
                  _Item(icon: Icons.swap_horiz_rounded, label: 'Bulk Import/Export', page: AdminPage.bulkImportExport, current: current, onTap: onSelect),
                  _Item(icon: Icons.cleaning_services_rounded, label: 'Database Cleanup', page: AdminPage.databaseCleanup, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('ANALYTICS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.payments_rounded, label: 'Driver Earnings', page: AdminPage.driverEarnings, current: current, onTap: onSelect),
                  _Item(icon: Icons.account_balance_wallet_rounded, label: 'Cash Limit', page: AdminPage.cashLimit, current: current, onTap: onSelect),
                  _Item(icon: Icons.rate_review_rounded, label: 'Food Reviews', page: AdminPage.foodReviews, current: current, onTap: onSelect),
                  _Item(icon: Icons.assessment_rounded, label: 'Reports', page: AdminPage.reports, current: current, onTap: onSelect),
                  _Item(icon: Icons.local_shipping_rounded, label: 'Dispatch Management', page: AdminPage.dispatchManagement, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('SETTINGS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.map_rounded, label: 'Vehicle Coverage', page: AdminPage.vehicleCoverage, current: current, onTap: onSelect),
                  _Item(icon: Icons.business_rounded, label: 'Business Models', page: AdminPage.businessModels, current: current, onTap: onSelect),
                  _Item(icon: Icons.person_add_rounded, label: 'Self-Registration', page: AdminPage.selfRegistration, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('REPORTS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.card_membership_rounded, label: 'Subscription Reports', page: AdminPage.subscriptionReports, current: current, onTap: onSelect),
                  _Item(icon: Icons.campaign_rounded, label: 'Campaign Reports', page: AdminPage.campaignReports, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('ANALYTICS', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.people_rounded, label: 'Customer Analytics', page: AdminPage.customerAnalytics, current: current, onTap: onSelect),
                  _Item(icon: Icons.store_rounded, label: 'Restaurant Analytics', page: AdminPage.restaurantAnalytics, current: current, onTap: onSelect),
                  _Item(icon: Icons.delivery_dining_rounded, label: 'Driver Analytics', page: AdminPage.driverAnalytics, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('MANAGEMENT', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.inventory_2_rounded, label: 'Inventory', page: AdminPage.inventoryManagement, current: current, onTap: onSelect),
                  _Item(icon: Icons.card_giftcard_rounded, label: 'Loyalty Program', page: AdminPage.loyaltyProgram, current: current, onTap: onSelect),
                  _Item(icon: Icons.people_outline_rounded, label: 'Referral Program', page: AdminPage.referralProgram, current: current, onTap: onSelect),
                  _Item(icon: Icons.local_offer_rounded, label: 'Promotions', page: AdminPage.promotions, current: current, onTap: onSelect),
                  _Item(icon: Icons.schedule_rounded, label: 'Schedule Management', page: AdminPage.scheduleManagement, current: current, onTap: onSelect),
                  _Item(icon: Icons.payment_rounded, label: 'Payment Methods', page: AdminPage.paymentMethods, current: current, onTap: onSelect),
                  _Item(icon: Icons.map_rounded, label: 'Delivery Zones', page: AdminPage.deliveryZones, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('SUPPORT', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.support_agent_rounded, label: 'Support Tickets', page: AdminPage.supportTickets, current: current, onTap: onSelect),
                  _Item(icon: Icons.feedback_rounded, label: 'Feedback', page: AdminPage.feedback, current: current, onTap: onSelect),
                  _Item(icon: Icons.notifications_rounded, label: 'Notifications', page: AdminPage.notifications, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('MONITORING', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.description_rounded, label: 'Audit Logs', page: AdminPage.auditLogs, current: current, onTap: onSelect),
                  _Item(icon: Icons.people_rounded, label: 'User Activity', page: AdminPage.userActivity, current: current, onTap: onSelect),
                  _Item(icon: Icons.health_and_safety_rounded, label: 'System Health', page: AdminPage.systemHealth, current: current, onTap: onSelect),
                  _Item(icon: Icons.api_rounded, label: 'API Logs', page: AdminPage.apiLogs, current: current, onTap: onSelect),
                  _Item(icon: Icons.speed_rounded, label: 'Performance', page: AdminPage.performanceMonitor, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('SYSTEM', style: TextStyle(color: Color(0xFF4B5563), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  _Item(icon: Icons.settings_rounded, label: 'Settings', page: AdminPage.settings, current: current, onTap: onSelect),
                  _Item(icon: Icons.notifications_active_rounded, label: 'Send Notification', page: AdminPage.sendNotification, current: current, onTap: onSelect),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFF1F2937), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initials(context.watch<AdminProvider>().adminName),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    context.watch<AdminProvider>().adminName.isEmpty ? 'Admin' : context.watch<AdminProvider>().adminName,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.watch<AdminProvider>().adminEmail,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final AdminPage page;
  final AdminPage current;
  final ValueChanged<AdminPage> onTap;
  final int? badge;
  const _Item({required this.icon, required this.label, required this.page, required this.current, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final selected = page == current;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : const Color(0xFF9CA3AF), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF9CA3AF), fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal))),
              if (badge != null)
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)), child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}