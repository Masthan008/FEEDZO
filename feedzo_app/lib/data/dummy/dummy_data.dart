import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';

class DummyData {
  static final UserModel currentUser = UserModel(
    id: 'u1',
    name: 'Alex Johnson',
    email: 'alex@example.com',
    phone: '+91 98765 43210',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    savedAddresses: [
      'Home - 42, MG Road, Koramangala, Bangalore 560034',
      'Work - 15, Indiranagar, Bangalore 560038',
    ],
  );

  static final List<Restaurant> restaurants = [
    Restaurant(
      id: 'r1',
      name: 'Burger Barn',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      ],
      cuisine: 'American, Burgers',
      rating: 4.5,
      deliveryTime: 25,
      deliveryFee: 30,
      minOrder: 150,
      isVeg: false,
      isOpen: true,
      address: 'Koramangala, Bangalore',
      tags: ['Trending', 'AI Pick'],
      menu: [
        MenuItem(
          id: 'm1',
          restaurantId: 'r1',
          name: 'Classic Smash Burger',
          description: 'Double smash patty, cheddar, pickles, special sauce',
          price: 249,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Burgers',
        ),
        MenuItem(
          id: 'm2',
          restaurantId: 'r1',
          name: 'Crispy Chicken Burger',
          description: 'Fried chicken, coleslaw, sriracha mayo',
          price: 229,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400',
          isVeg: false,
          isBestseller: false,
          category: 'Burgers',
        ),
        MenuItem(
          id: 'm3',
          restaurantId: 'r1',
          name: 'Veggie Delight Burger',
          description: 'Aloo tikki, lettuce, tomato, mint chutney',
          price: 179,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Burgers',
        ),
        MenuItem(
          id: 'm4',
          restaurantId: 'r1',
          name: 'Loaded Fries',
          description: 'Crispy fries with cheese sauce and jalapeños',
          price: 129,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
          isVeg: true,
          isBestseller: true,
          category: 'Sides',
        ),
        MenuItem(
          id: 'm5',
          restaurantId: 'r1',
          name: 'Chocolate Shake',
          description: 'Thick creamy chocolate milkshake',
          price: 149,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Drinks',
        ),
      ],
    ),
    Restaurant(
      id: 'r2',
      name: 'Spice Garden',
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600',
      ],
      cuisine: 'Indian, Biryani',
      rating: 4.7,
      deliveryTime: 35,
      deliveryFee: 20,
      minOrder: 200,
      isVeg: false,
      isOpen: true,
      address: 'Indiranagar, Bangalore',
      tags: ['Trending'],
      menu: [
        MenuItem(
          id: 'm6',
          restaurantId: 'r2',
          name: 'Chicken Biryani',
          description: 'Aromatic basmati rice with tender chicken pieces',
          price: 299,
          discount: 10,
          imageUrl:
              'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Biryani',
        ),
        MenuItem(
          id: 'm7',
          restaurantId: 'r2',
          name: 'Veg Biryani',
          description: 'Fragrant rice with seasonal vegetables and saffron',
          price: 229,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Biryani',
        ),
        MenuItem(
          id: 'm8',
          restaurantId: 'r2',
          name: 'Butter Chicken',
          description: 'Creamy tomato-based curry with tender chicken',
          price: 279,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Curries',
        ),
        MenuItem(
          id: 'm9',
          restaurantId: 'r2',
          name: 'Dal Makhani',
          description: 'Slow-cooked black lentils in rich buttery gravy',
          price: 199,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Curries',
        ),
        MenuItem(
          id: 'm10',
          restaurantId: 'r2',
          name: 'Garlic Naan',
          description: 'Soft leavened bread with garlic butter',
          price: 49,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Breads',
        ),
      ],
    ),
    Restaurant(
      id: 'r3',
      name: 'Pizza Palace',
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
      ],
      cuisine: 'Italian, Pizza',
      rating: 4.3,
      deliveryTime: 30,
      deliveryFee: 25,
      minOrder: 250,
      isVeg: false,
      isOpen: true,
      address: 'HSR Layout, Bangalore',
      tags: ['AI Pick'],
      menu: [
        MenuItem(
          id: 'm11',
          restaurantId: 'r3',
          name: 'Margherita Pizza',
          description: 'Classic tomato sauce, fresh mozzarella, basil',
          price: 299,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
          isVeg: true,
          isBestseller: true,
          category: 'Pizzas',
        ),
        MenuItem(
          id: 'm12',
          restaurantId: 'r3',
          name: 'BBQ Chicken Pizza',
          description: 'Smoky BBQ sauce, grilled chicken, red onions',
          price: 379,
          discount: 15,
          imageUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Pizzas',
        ),
        MenuItem(
          id: 'm13',
          restaurantId: 'r3',
          name: 'Pasta Arrabbiata',
          description: 'Penne in spicy tomato sauce with garlic',
          price: 249,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Pasta',
        ),
        MenuItem(
          id: 'm14',
          restaurantId: 'r3',
          name: 'Tiramisu',
          description: 'Classic Italian dessert with mascarpone',
          price: 179,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Desserts',
        ),
      ],
    ),
    Restaurant(
      id: 'r4',
      name: 'Sushi Zen',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
      ],
      cuisine: 'Japanese, Sushi',
      rating: 4.6,
      deliveryTime: 40,
      deliveryFee: 50,
      minOrder: 400,
      isVeg: false,
      isOpen: true,
      address: 'Whitefield, Bangalore',
      tags: ['Trending', 'AI Pick'],
      menu: [
        MenuItem(
          id: 'm15',
          restaurantId: 'r4',
          name: 'Salmon Nigiri (6 pcs)',
          description: 'Fresh Atlantic salmon over seasoned rice',
          price: 449,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Nigiri',
        ),
        MenuItem(
          id: 'm16',
          restaurantId: 'r4',
          name: 'Dragon Roll',
          description: 'Shrimp tempura, avocado, cucumber, eel sauce',
          price: 549,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1617196034099-5b4e5e4e4e4e?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Rolls',
        ),
        MenuItem(
          id: 'm17',
          restaurantId: 'r4',
          name: 'Miso Soup',
          description: 'Traditional Japanese soup with tofu and seaweed',
          price: 99,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Soups',
        ),
      ],
    ),
    Restaurant(
      id: 'r5',
      name: 'Green Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      ],
      cuisine: 'Healthy, Salads',
      rating: 4.4,
      deliveryTime: 20,
      deliveryFee: 15,
      minOrder: 150,
      isVeg: true,
      isOpen: true,
      address: 'Jayanagar, Bangalore',
      tags: ['AI Pick'],
      menu: [
        MenuItem(
          id: 'm18',
          restaurantId: 'r5',
          name: 'Quinoa Power Bowl',
          description: 'Quinoa, roasted veggies, tahini dressing',
          price: 299,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
          isVeg: true,
          isBestseller: true,
          category: 'Bowls',
        ),
        MenuItem(
          id: 'm19',
          restaurantId: 'r5',
          name: 'Avocado Toast',
          description: 'Sourdough, smashed avocado, cherry tomatoes',
          price: 199,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Toasts',
        ),
        MenuItem(
          id: 'm20',
          restaurantId: 'r5',
          name: 'Green Smoothie',
          description: 'Spinach, banana, mango, coconut water',
          price: 149,
          discount: 10,
          imageUrl:
              'https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=400',
          isVeg: true,
          isBestseller: true,
          category: 'Drinks',
        ),
      ],
    ),
    Restaurant(
      id: 'r6',
      name: 'Taco Fiesta',
      imageUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
      ],
      cuisine: 'Mexican, Tacos',
      rating: 4.2,
      deliveryTime: 28,
      deliveryFee: 30,
      minOrder: 200,
      isVeg: false,
      isOpen: false,
      address: 'BTM Layout, Bangalore',
      tags: ['Trending'],
      menu: [
        MenuItem(
          id: 'm21',
          restaurantId: 'r6',
          name: 'Chicken Tacos (3 pcs)',
          description: 'Grilled chicken, pico de gallo, guacamole',
          price: 249,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
          isVeg: false,
          isBestseller: true,
          category: 'Tacos',
        ),
        MenuItem(
          id: 'm22',
          restaurantId: 'r6',
          name: 'Veggie Burrito',
          description: 'Black beans, rice, cheese, salsa, sour cream',
          price: 229,
          discount: 0,
          imageUrl:
              'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400',
          isVeg: true,
          isBestseller: false,
          category: 'Burritos',
        ),
      ],
    ),
  ];

  static final List<Map<String, dynamic>> categories = [
    {'name': 'Burgers', 'emoji': '🍔'},
    {'name': 'Pizza', 'emoji': '🍕'},
    {'name': 'Biryani', 'emoji': '🍛'},
    {'name': 'Sushi', 'emoji': '🍱'},
    {'name': 'Healthy', 'emoji': '🥗'},
    {'name': 'Tacos', 'emoji': '🌮'},
    {'name': 'Desserts', 'emoji': '🍰'},
    {'name': 'Drinks', 'emoji': '🥤'},
  ];

  static final List<Map<String, dynamic>> aiInsights = [
    {
      'title': 'Order Surge Detected',
      'body':
          'Your orders increased by 18% this week compared to last week. Peak hours are 12–2 PM and 7–9 PM.',
      'icon': Icons.trending_up_rounded,
      'color': 0xFF4CAF50,
    },
    {
      'title': 'Top Performing Item',
      'body':
          'Classic Smash Burger is your best seller with 142 orders this month. Consider featuring it prominently.',
      'icon': Icons.emoji_events_rounded,
      'color': 0xFFFF6B00,
    },
    {
      'title': 'Customer Retention',
      'body':
          '68% of your customers are repeat buyers. Loyalty rewards could push this to 80%+.',
      'icon': Icons.favorite_rounded,
      'color': 0xFFE91E63,
    },
    {
      'title': 'Revenue Forecast',
      'body':
          'Based on current trends, you\'re on track to hit ₹1.2L revenue this month — 12% above target.',
      'icon': Icons.currency_rupee_rounded,
      'color': 0xFF9C27B0,
    },
    {
      'title': 'Menu Optimization',
      'body':
          'Loaded Fries has a 94% satisfaction rate. Adding a combo deal could increase average order value by ₹45.',
      'icon': Icons.restaurant_menu_rounded,
      'color': 0xFF2196F3,
    },
  ];

  static final List<Map<String, dynamic>> reviewInsights = [
    {
      'label': 'Taste',
      'score': 4.7,
      'comment': 'Customers love the flavors. Spice levels are well-balanced.',
    },
    {
      'label': 'Packaging',
      'score': 4.2,
      'comment': 'Good packaging but some customers report soggy fries.',
    },
    {
      'label': 'Delivery Speed',
      'score': 4.0,
      'comment': 'Average delivery time is 28 min. Room for improvement.',
    },
    {
      'label': 'Value for Money',
      'score': 4.5,
      'comment': 'Customers feel portions are generous for the price.',
    },
  ];
}
