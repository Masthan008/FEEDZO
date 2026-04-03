class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dob;
  final String avatarUrl;
  final String role;
  final String status;
  final List<String> savedAddresses;

  // ── New fields for production readiness ──
  final List<String> favoriteRestaurants;
  final List<String> favoriteItems;
  final double walletBalance;
  final int loyaltyPoints;
  final String? referralCode;
  final Map<String, bool> notificationPrefs;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.gender = '',
    this.dob = '',
    this.avatarUrl = '',
    this.role = 'customer',
    this.status = 'approved',
    this.savedAddresses = const [],
    this.favoriteRestaurants = const [],
    this.favoriteItems = const [],
    this.walletBalance = 0,
    this.loyaltyPoints = 0,
    this.referralCode,
    this.notificationPrefs = const {
      'orders': true,
      'promotions': true,
      'delivery': true,
    },
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      role: map['role'] ?? 'customer',
      status: map['status'] ?? 'approved',
      savedAddresses: List<String>.from(map['savedAddresses'] ?? []),
      favoriteRestaurants:
          List<String>.from(map['favoriteRestaurants'] ?? []),
      favoriteItems: List<String>.from(map['favoriteItems'] ?? []),
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0,
      loyaltyPoints: (map['loyaltyPoints'] as num?)?.toInt() ?? 0,
      referralCode: map['referralCode'] as String?,
      notificationPrefs:
          (map['notificationPrefs'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v == true)) ??
              const {'orders': true, 'promotions': true, 'delivery': true},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'avatarUrl': avatarUrl,
      'role': role,
      'status': status,
      'savedAddresses': savedAddresses,
      'favoriteRestaurants': favoriteRestaurants,
      'favoriteItems': favoriteItems,
      if (walletBalance > 0) 'walletBalance': walletBalance,
      if (loyaltyPoints > 0) 'loyaltyPoints': loyaltyPoints,
      if (referralCode != null) 'referralCode': referralCode,
      'notificationPrefs': notificationPrefs,
    };
  }

  /// Check if a restaurant is in favorites.
  bool isFavoriteRestaurant(String restaurantId) =>
      favoriteRestaurants.contains(restaurantId);

  /// Check if an item is in favorites.
  bool isFavoriteItem(String itemId) => favoriteItems.contains(itemId);
}
