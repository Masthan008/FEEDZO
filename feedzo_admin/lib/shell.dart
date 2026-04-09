import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'widgets/sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/users_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/ai_insights_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/cod_settlement_screen.dart';
import 'screens/coupons_screen.dart';
import 'screens/refunds_screen.dart';
import 'screens/incentives_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/banners_screen.dart';
import 'screens/send_notification_screen.dart';
import 'screens/recommended_restaurants_screen.dart';
import 'screens/hike_charges_screen.dart';
import 'screens/driver_payouts_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/zones_screen.dart';
import 'screens/cuisines_screen.dart';
import 'screens/food_addons_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/customer_wallet_screen.dart';
import 'screens/restaurant_withdrawals_screen.dart';
import 'screens/language_settings_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'screens/email_templates_screen.dart';
import 'screens/social_media_screen.dart';
import 'screens/legal_pages_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/chat_system_screen.dart';
import 'screens/newsletter_screen.dart';
import 'screens/app_version_screen.dart';
import 'screens/landing_page_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/third_party_config_screen.dart';
import 'screens/bulk_import_export_screen.dart';
import 'screens/database_cleanup_screen.dart';
import 'screens/driver_earnings_screen.dart';
import 'screens/cash_limit_screen.dart';
import 'screens/food_reviews_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/dispatch_management_screen.dart';
import 'screens/vehicle_coverage_screen.dart';
import 'screens/business_models_screen.dart';
import 'screens/self_registration_screen.dart';
import 'screens/subscription_reports_screen.dart';
import 'screens/campaign_reports_screen.dart';
import 'screens/customer_analytics_screen.dart';
import 'screens/restaurant_analytics_screen.dart';
import 'screens/driver_analytics_screen.dart';
import 'screens/inventory_management_screen.dart';
import 'screens/loyalty_program_screen.dart';
import 'screens/referral_program_screen.dart';
import 'screens/promotions_screen.dart';
import 'screens/schedule_management_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/delivery_zones_screen.dart';
import 'screens/order_analytics_screen.dart';
import 'screens/support_tickets_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/audit_logs_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/user_activity_screen.dart';
import 'screens/system_health_screen.dart';
import 'screens/api_logs_screen.dart';
import 'screens/performance_monitor_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminPage _current = AdminPage.dashboard;

  Widget get _screen {
    switch (_current) {
      case AdminPage.dashboard: return const DashboardScreen();
      case AdminPage.orders: return const OrdersScreen();
      case AdminPage.restaurants: return const RestaurantsScreen();
      case AdminPage.drivers: return const DriversScreen();
      case AdminPage.users: return const UsersScreen();
      case AdminPage.earnings: return const EarningsScreen();
      case AdminPage.coupons: return const CouponsScreen();
      case AdminPage.banners: return const BannersScreen();
      case AdminPage.refunds: return const RefundsScreen();
      case AdminPage.incentives: return const IncentivesScreen();
      case AdminPage.recommended: return const RecommendedRestaurantsScreen();
      case AdminPage.aiInsights: return const AIInsightsScreen();
      case AdminPage.alerts: return const AlertsScreen();
      case AdminPage.codSettlement: return const CodSettlementScreen();
      case AdminPage.settings: return const SettingsScreen();
      case AdminPage.sendNotification: return const SendNotificationScreen();
      case AdminPage.hikeCharges: return const HikeChargesScreen();
      case AdminPage.driverPayouts: return const DriverPayoutsScreen();
      case AdminPage.reviews: return const AdminReviewsScreen();
      case AdminPage.zones: return const ZonesScreen();
      case AdminPage.cuisines: return const CuisinesScreen();
      case AdminPage.foodAddons: return const FoodAddonsScreen();
      case AdminPage.subscriptions: return const SubscriptionsScreen();
      case AdminPage.customerWallet: return const CustomerWalletScreen();
      case AdminPage.restaurantWithdrawals: return const RestaurantWithdrawalsScreen();
      case AdminPage.languageSettings: return const LanguageSettingsScreen();
      case AdminPage.themeSettings: return const ThemeSettingsScreen();
      case AdminPage.emailTemplates: return const EmailTemplatesScreen();
      case AdminPage.socialMedia: return const SocialMediaScreen();
      case AdminPage.legalPages: return const LegalPagesScreen();
      case AdminPage.aboutUs: return const AboutUsScreen();
      case AdminPage.chatSystem: return const ChatSystemScreen();
      case AdminPage.newsletter: return const NewsletterScreen();
      case AdminPage.appVersion: return const AppVersionScreen();
      case AdminPage.landingPage: return const LandingPageScreen();
      case AdminPage.tips: return const TipsScreen();
      case AdminPage.verification: return const VerificationScreen();
      case AdminPage.thirdPartyConfig: return const ThirdPartyConfigScreen();
      case AdminPage.bulkImportExport: return const BulkImportExportScreen();
      case AdminPage.databaseCleanup: return const DatabaseCleanupScreen();
      case AdminPage.driverEarnings: return const DriverEarningsScreen();
      case AdminPage.cashLimit: return const CashLimitScreen();
      case AdminPage.foodReviews: return const FoodReviewsScreen();
      case AdminPage.reports: return const ReportsScreen();
      case AdminPage.dispatchManagement: return const DispatchManagementScreen();
      case AdminPage.vehicleCoverage: return const VehicleCoverageScreen();
      case AdminPage.businessModels: return const BusinessModelsScreen();
      case AdminPage.selfRegistration: return const SelfRegistrationScreen();
      case AdminPage.subscriptionReports: return const SubscriptionReportsScreen();
      case AdminPage.campaignReports: return const CampaignReportsScreen();
      case AdminPage.customerAnalytics: return const CustomerAnalyticsScreen();
      case AdminPage.restaurantAnalytics: return const RestaurantAnalyticsScreen();
      case AdminPage.driverAnalytics: return const DriverAnalyticsScreen();
      case AdminPage.inventoryManagement: return const InventoryManagementScreen();
      case AdminPage.loyaltyProgram: return const LoyaltyProgramScreen();
      case AdminPage.referralProgram: return const ReferralProgramScreen();
      case AdminPage.promotions: return const PromotionsScreen();
      case AdminPage.scheduleManagement: return const ScheduleManagementScreen();
      case AdminPage.paymentMethods: return const PaymentMethodsScreen();
      case AdminPage.deliveryZones: return const DeliveryZonesScreen();
      case AdminPage.orderAnalytics: return const OrderAnalyticsScreen();
      case AdminPage.supportTickets: return const SupportTicketsScreen();
      case AdminPage.notifications: return const NotificationsScreen();
      case AdminPage.auditLogs: return const AuditLogsScreen();
      case AdminPage.feedback: return const FeedbackScreen();
      case AdminPage.userActivity: return const UserActivityScreen();
      case AdminPage.systemHealth: return const SystemHealthScreen();
      case AdminPage.apiLogs: return const ApiLogsScreen();
      case AdminPage.performanceMonitor: return const PerformanceMonitorScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Sidebar(
            current: _current,
            onSelect: (p) => setState(() => _current = p),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_current),
                child: _screen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}