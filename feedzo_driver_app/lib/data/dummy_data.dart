import '../models/order_model.dart';
import '../models/driver_model.dart';
import '../models/earning_model.dart';

final dummyDriver = DriverModel(
  id: 'd001',
  name: 'Ravi Kumar',
  phone: '+91 98765 43210',
  email: 'ravi.kumar@feedzo.com',
  vehicleType: 'Motorcycle',
  vehicleNumber: 'TN 09 AB 1234',
  totalDeliveries: 248,
  rating: 4.8,
  avatarInitials: 'RK',
);

List<DriverOrder> dummyOrders = [
  DriverOrder(
    id: 'ORD-001',
    restaurantName: 'Spice Garden',
    restaurantAddress: '12, Anna Salai, Chennai',
    customerName: 'Priya Sharma',
    customerAddress: '45, T Nagar, Chennai - 600017',
    customerPhone: '+91 91234 56789',
    distance: 2.4,
    earnings: 45.0,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    items: const [
      OrderItem(name: 'Butter Chicken', quantity: 1, price: 280),
      OrderItem(name: 'Garlic Naan', quantity: 2, price: 40),
      OrderItem(name: 'Mango Lassi', quantity: 1, price: 80),
    ],
  ),
  DriverOrder(
    id: 'ORD-002',
    restaurantName: 'Dosa Palace',
    restaurantAddress: '8, Usman Road, T Nagar',
    customerName: 'Arjun Mehta',
    customerAddress: '22, Velachery Main Road, Chennai - 600042',
    customerPhone: '+91 98765 12345',
    distance: 3.8,
    earnings: 60.0,
    status: OrderStatus.accepted,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    items: const [
      OrderItem(name: 'Masala Dosa', quantity: 2, price: 120),
      OrderItem(name: 'Filter Coffee', quantity: 2, price: 50),
      OrderItem(name: 'Vada', quantity: 3, price: 30),
    ],
  ),
  DriverOrder(
    id: 'ORD-003',
    restaurantName: 'Biryani House',
    restaurantAddress: '5, Greams Road, Chennai',
    customerName: 'Sneha Patel',
    customerAddress: '10, Adyar, Chennai - 600020',
    customerPhone: '+91 87654 32109',
    distance: 5.1,
    earnings: 75.0,
    status: OrderStatus.delivered,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    items: const [
      OrderItem(name: 'Chicken Biryani', quantity: 2, price: 320),
      OrderItem(name: 'Raita', quantity: 1, price: 40),
    ],
  ),
  DriverOrder(
    id: 'ORD-004',
    restaurantName: 'Pizza Corner',
    restaurantAddress: '3, Nungambakkam High Road',
    customerName: 'Karthik Raj',
    customerAddress: '67, Kodambakkam, Chennai - 600024',
    customerPhone: '+91 76543 21098',
    distance: 4.2,
    earnings: 55.0,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    items: const [
      OrderItem(name: 'Margherita Pizza', quantity: 1, price: 350),
      OrderItem(name: 'Garlic Bread', quantity: 1, price: 120),
      OrderItem(name: 'Coke', quantity: 2, price: 60),
    ],
  ),
  DriverOrder(
    id: 'ORD-005',
    restaurantName: 'Burger Barn',
    restaurantAddress: '18, Mount Road, Chennai',
    customerName: 'Divya Nair',
    customerAddress: '33, Mylapore, Chennai - 600004',
    customerPhone: '+91 65432 10987',
    distance: 1.9,
    earnings: 35.0,
    status: OrderStatus.delivered,
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    items: const [
      OrderItem(name: 'Classic Burger', quantity: 2, price: 180),
      OrderItem(name: 'French Fries', quantity: 2, price: 90),
    ],
  ),
];

List<EarningEntry> dummyEarnings = [
  EarningEntry(
    orderId: 'ORD-003',
    restaurantName: 'Biryani House',
    amount: 75.0,
    date: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  EarningEntry(
    orderId: 'ORD-005',
    restaurantName: 'Burger Barn',
    amount: 35.0,
    date: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  EarningEntry(
    orderId: 'ORD-006',
    restaurantName: 'Spice Garden',
    amount: 50.0,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  EarningEntry(
    orderId: 'ORD-007',
    restaurantName: 'Dosa Palace',
    amount: 40.0,
    date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
  ),
  EarningEntry(
    orderId: 'ORD-008',
    restaurantName: 'Pizza Corner',
    amount: 65.0,
    date: DateTime.now().subtract(const Duration(days: 2)),
  ),
  EarningEntry(
    orderId: 'ORD-009',
    restaurantName: 'Biryani House',
    amount: 80.0,
    date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
  ),
  EarningEntry(
    orderId: 'ORD-010',
    restaurantName: 'Burger Barn',
    amount: 45.0,
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

// ─── COD Data ─────────────────────────────────────────────────────────────────

List<CodEntry> dummyCodEntries = [
  CodEntry(orderId: 'ORD-003', customerName: 'Sneha Patel', restaurantName: 'Biryani House', orderAmount: 680, collectedAt: DateTime.now().subtract(const Duration(hours: 2)), status: CodStatus.submitted, submittedAmount: 680),
  CodEntry(orderId: 'ORD-005', customerName: 'Divya Nair', restaurantName: 'Burger Barn', orderAmount: 450, collectedAt: DateTime.now().subtract(const Duration(hours: 4)), status: CodStatus.submitted, submittedAmount: 450),
  CodEntry(orderId: 'ORD-011', customerName: 'Karthik Raj', restaurantName: 'Spice Garden', orderAmount: 320, collectedAt: DateTime.now().subtract(const Duration(minutes: 40)), status: CodStatus.pending, submittedAmount: 0),
  CodEntry(orderId: 'ORD-012', customerName: 'Priya Sharma', restaurantName: 'Pizza Corner', orderAmount: 590, collectedAt: DateTime.now().subtract(const Duration(minutes: 20)), status: CodStatus.pending, submittedAmount: 0),
  CodEntry(orderId: 'ORD-013', customerName: 'Alex Johnson', restaurantName: 'Dosa Palace', orderAmount: 210, collectedAt: DateTime.now().subtract(const Duration(minutes: 10)), status: CodStatus.pending, submittedAmount: 0),
];

final List<CodDailySummary> dummyCodHistory = [
  CodDailySummary(date: DateTime.now(), totalCodOrders: 5, totalCodCollected: 2250, totalSubmitted: 1130),
  CodDailySummary(date: DateTime.now().subtract(const Duration(days: 1)), totalCodOrders: 7, totalCodCollected: 3100, totalSubmitted: 3100),
  CodDailySummary(date: DateTime.now().subtract(const Duration(days: 2)), totalCodOrders: 4, totalCodCollected: 1680, totalSubmitted: 1680),
  CodDailySummary(date: DateTime.now().subtract(const Duration(days: 3)), totalCodOrders: 6, totalCodCollected: 2540, totalSubmitted: 2540),
  CodDailySummary(date: DateTime.now().subtract(const Duration(days: 4)), totalCodOrders: 3, totalCodCollected: 980, totalSubmitted: 800),
];
