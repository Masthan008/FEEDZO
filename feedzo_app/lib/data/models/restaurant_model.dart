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
    };
  }

  double get discountedPrice => price * (1 - discount / 100);
}
