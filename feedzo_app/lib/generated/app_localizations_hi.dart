// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'फीड्जो';

  @override
  String get tagline => 'भोजन डिलीवरी आसान बनाया गया';

  @override
  String get loginTitle => 'वापसी पर स्वागत है';

  @override
  String get loginSubtitle => 'जारी रखने के लिए साइन इन करें';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String get enterOtp => 'को भेजा गया OTP दर्ज करें';

  @override
  String get resendOtp => 'OTP पुनः भेजें';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get homeTitle => 'होम';

  @override
  String get searchHint => 'रेस्तरां या व्यंजन खोजें';

  @override
  String mealsUnder(Object value) {
    return '₹$value से कम भोजन';
  }

  @override
  String priceValue(Object value) {
    return '₹$value';
  }

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get recommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String get allRestaurants => 'सभी रेस्तरां';

  @override
  String get vegOnly => 'सिर्फ शाकाहारी';

  @override
  String get filters => 'फिल्टर';

  @override
  String get nearAndFast => 'निकट और तेज';

  @override
  String get schedule => 'अनुसूची';

  @override
  String get greatOffers => 'बेहतरीन ऑफर';

  @override
  String get restaurantDetail => 'रेस्तरां विवरण';

  @override
  String get menu => 'मेनू';

  @override
  String get addToCart => 'कार्ट में जोड़ें';

  @override
  String get viewCart => 'कार्ट देखें';

  @override
  String itemCount(Object count) {
    return '$count आइटम';
  }

  @override
  String get cartTitle => 'आपका कार्ट';

  @override
  String get checkout => 'चेकआउट';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get deliveryFee => 'डिलीवरी शुल्क';

  @override
  String get packagingCharges => 'पैकेजिंग शुल्क';

  @override
  String get toPay => 'भुगतान करें';

  @override
  String get orderStatus => 'ऑर्डर स्थिति';

  @override
  String get trackOrder => 'अपना ऑर्डर ट्रैक करें';

  @override
  String get orderPlaced => 'ऑर्डर दिया गया';

  @override
  String get preparing => 'तैयारी हो रही है';

  @override
  String get pickedUp => 'उठा लिया गया';

  @override
  String get outForDelivery => 'डिलीवरी के लिए बाहर';

  @override
  String get delivered => 'डिलीवर किया गया';

  @override
  String estimatedTime(Object time) {
    return 'अनुमानित: $time मिनट';
  }

  @override
  String get deliveryOtp => 'डिलीवरी OTP';

  @override
  String get liveTracking => 'लाइव ट्रैकिंग';

  @override
  String get orderSummary => 'ऑर्डर सारांश';

  @override
  String get cancelOrder => 'ऑर्डर रद्द करें';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get myOrders => 'मेरे ऑर्डर';

  @override
  String get paymentMethods => 'भुगतान विधियाँ';

  @override
  String get addresses => 'पते';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get privacySettings => 'गोपनीयता सेटिंग्स';

  @override
  String get marketingPreferences => 'मार्केटिंग प्राथमिकताएँ';

  @override
  String get loyaltyProgram => 'लॉयल्टी पॉइंट्स';

  @override
  String totalPoints(Object points) {
    return '$points पॉइंट्स';
  }

  @override
  String currentTier(Object tier) {
    return '$tier सदस्य';
  }

  @override
  String get nearbyRestaurants => 'आपके पास';

  @override
  String get sortBy => 'क्रमबद्ध करें';
}
