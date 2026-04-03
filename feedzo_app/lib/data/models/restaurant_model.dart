class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> imageUrls;
  final String cuisine;
  final double rating;
  final int deliveryTime; // minutes
  final double deliveryFee;
  final double minOrder;
  final bool isVeg;
  final bool isOpen;
  final String address;
  final List<String> tags;
  final List<MenuItem> menu;
  final bool isRecommended;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.imageUrls,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    required this.isVeg,
    required this.isOpen,
    required this.address,
    required this.tags,
    this.menu = const [],
    this.isRecommended = false,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map, String id) {
    return Restaurant(
      id: id,
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ??
          (map['imageUrls'] is List && (map['imageUrls'] as List).isNotEmpty
              ? map['imageUrls'][0].toString()
              : ''),
      imageUrls: map['imageUrls'] is List
          ? List<String>.from(map['imageUrls'])
          : [],
      cuisine: map['cuisine']?.toString() ?? '',
      rating: double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      deliveryTime: int.tryParse(map['deliveryTime']?.toString() ?? '0') ?? 0,
      deliveryFee: double.tryParse(map['deliveryFee']?.toString() ?? '0.0') ?? 0.0,
      minOrder: double.tryParse(map['minOrder']?.toString() ?? '0.0') ?? 0.0,
      isVeg: map['isVeg'] == true || map['isVeg'] == 'true',
      isOpen: map['isOpen'] == null || map['isOpen'] == true || map['isOpen'] == 'true',
      address: map['address']?.toString() ?? '',
      tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
      menu: map['menu'] is List
          ? (map['menu'] as List)
              .whereType<Map<String, dynamic>>()
              .map((m) => MenuItem.fromMap(m, m['id']?.toString() ?? ''))
               .toList()
          : [],
      isRecommended: map['isRecommended'] == true || map['isRecommended'] == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'cuisine': cuisine,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'minOrder': minOrder,
      'isVeg': isVeg,
      'isOpen': isOpen,
      'address': address,
      'tags': tags,
      'menu': menu.map((m) => m.toMap()..['id'] = m.id).toList(),
    };
  }

  String get firstImage => imageUrl.isNotEmpty
      ? imageUrl
      : (imageUrls.isNotEmpty ? imageUrls.first : '');
}

/// Represents an add-on option for a menu item (e.g. "Extra cheese ₹30").
class MenuAddon {
  final String name;
  final double price;

  const MenuAddon({required this.name, required this.price});

  factory MenuAddon.fromMap(Map<String, dynamic> map) {
    return MenuAddon(
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

/// Represents a variant option for a menu item (e.g. "Large +₹50").
class MenuVariant {
  final String name; // "Small", "Medium", "Large"
  final double priceAdjustment; // +₹0, +₹30, +₹60

  const MenuVariant({required this.name, this.priceAdjustment = 0});

  factory MenuVariant.fromMap(Map<String, dynamic> map) {
    return MenuVariant(
      name: map['name']?.toString() ?? '',
      priceAdjustment: (map['priceAdjustment'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'priceAdjustment': priceAdjustment};
}

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final double discount;
  final String imageUrl;
  final bool isVeg;
  final String category;
  final bool isAvailable;
  final bool isBestseller;

  // ── New fields for production readiness ──
  final List<MenuAddon> addons;
  final List<MenuVariant> variants;
  final List<String> dietaryTags; // "Gluten-free", "Jain", "Keto"
  final int? prepTimeMinutes;
  final int? calories;
  final int spiceLevel; // 0-5
  final int orderCount; // popularity metric

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.discount,
    required this.imageUrl,
    required this.isVeg,
    required this.category,
    this.isAvailable = true,
    this.isBestseller = false,
    this.addons = const [],
    this.variants = const [],
    this.dietaryTags = const [],
    this.prepTimeMinutes,
    this.calories,
    this.spiceLevel = 0,
    this.orderCount = 0,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    return MenuItem(
      id: id,
      restaurantId: map['restaurantId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      discount: double.tryParse(map['discount']?.toString() ?? '0.0') ?? 0.0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      isVeg: map['isVeg'] == true || map['isVeg'] == 'true',
      category: map['category']?.toString() ?? '',
      isAvailable: map['isAvailable'] == null || map['isAvailable'] == true || map['isAvailable'] == 'true',
      isBestseller: map['isBestseller'] == true || map['isBestseller'] == 'true',
      // New fields
      addons: (map['addons'] as List?)
              ?.map((a) => MenuAddon.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      variants: (map['variants'] as List?)
              ?.map((v) => MenuVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      dietaryTags: (map['dietaryTags'] as List?)?.cast<String>() ?? [],
      prepTimeMinutes: (map['prepTimeMinutes'] as num?)?.toInt(),
      calories: (map['calories'] as num?)?.toInt(),
      spiceLevel: (map['spiceLevel'] as num?)?.toInt() ?? 0,
      orderCount: (map['orderCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'category': category,
      'isAvailable': isAvailable,
      'isBestseller': isBestseller,
      if (addons.isNotEmpty) 'addons': addons.map((a) => a.toMap()).toList(),
      if (variants.isNotEmpty)
        'variants': variants.map((v) => v.toMap()).toList(),
      if (dietaryTags.isNotEmpty) 'dietaryTags': dietaryTags,
      if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
      if (calories != null) 'calories': calories,
      if (spiceLevel > 0) 'spiceLevel': spiceLevel,
      if (orderCount > 0) 'orderCount': orderCount,
    };
  }

  double get discountedPrice => price * (1 - discount / 100);

  /// Whether this item has customization options.
  bool get hasCustomization => addons.isNotEmpty || variants.isNotEmpty;
}
