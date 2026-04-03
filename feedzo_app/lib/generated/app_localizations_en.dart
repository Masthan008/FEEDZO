// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Feedzo';

  @override
  String get tagline => 'Food Delivery Made Simple';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get continueLabel => 'Continue';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get enterOtp => 'Enter OTP sent to';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get createAccount => 'Create Account';

  @override
  String get homeTitle => 'Home';

  @override
  String get searchHint => 'Search for restaurants or dishes';

  @override
  String mealsUnder(Object value) {
    return 'MEALS UNDER';
  }

  @override
  String priceValue(Object value) {
    return '₹$value';
  }

  @override
  String get categories => 'Categories';

  @override
  String get recommendedForYou => 'RECOMMENDED FOR YOU';

  @override
  String get allRestaurants => 'ALL RESTAURANTS';

  @override
  String get vegOnly => 'VEG ONLY';

  @override
  String get filters => 'Filters';

  @override
  String get nearAndFast => 'Near & Fast';

  @override
  String get schedule => 'Schedule';

  @override
  String get greatOffers => 'Great Offers';

  @override
  String get restaurantDetail => 'Restaurant Details';

  @override
  String get menu => 'Menu';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get viewCart => 'View Cart';

  @override
  String itemCount(Object count) {
    return '$count ITEMS';
  }

  @override
  String get cartTitle => 'Your Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get packagingCharges => 'Packaging Charges';

  @override
  String get toPay => 'To Pay';

  @override
  String get orderStatus => 'Order Status';

  @override
  String get trackOrder => 'Track Your Order';

  @override
  String get orderPlaced => 'Order Placed';

  @override
  String get preparing => 'Preparing';

  @override
  String get pickedUp => 'Picked Up';

  @override
  String get outForDelivery => 'Out for Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String estimatedTime(Object time) {
    return 'Estimated: $time min';
  }

  @override
  String get deliveryOtp => 'Delivery OTP';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get profileTitle => 'Profile';

  @override
  String get myOrders => 'My Orders';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get addresses => 'Addresses';

  @override
  String get favorites => 'Favorites';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get marketingPreferences => 'Marketing Preferences';

  @override
  String get loyaltyProgram => 'Loyalty Points';

  @override
  String totalPoints(Object points) {
    return '$points Points';
  }

  @override
  String currentTier(Object tier) {
    return '$tier Member';
  }

  @override
  String get nearbyRestaurants => 'Near You';

  @override
  String get sortBy => 'Sort by';
}
