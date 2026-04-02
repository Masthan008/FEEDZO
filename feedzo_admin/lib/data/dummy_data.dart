import 'models.dart';

final List<Driver> dummyDrivers = [
  Driver(id: 'drv1', name: 'Ravi Kumar', phone: '+91 98765 43210', vehicle: 'Motorcycle · TN09AB1234', status: DriverStatus.available, totalDeliveries: 248, rating: 4.8, totalEarnings: 12400),
  Driver(id: 'drv2', name: 'Suresh Babu', phone: '+91 87654 32109', vehicle: 'Scooter · TN07CD5678', status: DriverStatus.busy, totalDeliveries: 185, rating: 4.6, totalEarnings: 9250, currentOrderId: 'ord3'),
  Driver(id: 'drv3', name: 'Manoj Singh', phone: '+91 76543 21098', vehicle: 'Motorcycle · TN11EF9012', status: DriverStatus.offline, totalDeliveries: 92, rating: 4.3, totalEarnings: 4600),
  Driver(id: 'drv4', name: 'Pradeep Nair', phone: '+91 65432 10987', vehicle: 'Bicycle · N/A', status: DriverStatus.available, totalDeliveries: 310, rating: 4.9, totalEarnings: 15500),
  Driver(id: 'drv5', name: 'Arun Krishnan', phone: '+91 54321 09876', vehicle: 'Scooter · TN05GH3456', status: DriverStatus.offline, totalDeliveries: 44, rating: 3.9, totalEarnings: 2200),
];

final List<AdminRestaurant> dummyRestaurants = [
  AdminRestaurant(id: 'rst1', name: 'Spice Garden', cuisine: 'Indian, Biryani', location: 'Indiranagar, Bangalore', rating: 4.7, status: RestaurantStatus.active, totalOrders: 1240, totalRevenue: 186000, walletBalance: 12400, commissionRate: 0.10, transactions: [
    Transaction(id: 't1', orderId: 'ord1', amount: 270, commission: 30, type: TransactionType.commission, date: DateTime.now().subtract(const Duration(hours: 2)), note: 'Commission 10%', paid: true),
    Transaction(id: 't2', orderId: '-', amount: 5000, commission: 0, type: TransactionType.payout, date: DateTime.now().subtract(const Duration(days: 1)), note: 'Weekly payout', paid: true),
  ]),
  AdminRestaurant(id: 'rst2', name: 'Burger Barn', cuisine: 'American, Burgers', location: 'Koramangala, Bangalore', rating: 4.5, status: RestaurantStatus.active, totalOrders: 980, totalRevenue: 147000, walletBalance: 8750, commissionRate: 0.12, transactions: [
    Transaction(id: 't3', orderId: 'ord3', amount: 224, commission: 25, type: TransactionType.commission, date: DateTime.now().subtract(const Duration(hours: 5)), note: 'Commission 12%', paid: false),
  ]),
  AdminRestaurant(id: 'rst3', name: 'Pizza Palace', cuisine: 'Italian, Pizza', location: 'HSR Layout, Bangalore', rating: 4.3, status: RestaurantStatus.active, totalOrders: 760, totalRevenue: 114000, walletBalance: 6200, commissionRate: 0.08, transactions: []),
  AdminRestaurant(id: 'rst4', name: 'Sushi Zen', cuisine: 'Japanese, Sushi', location: 'Whitefield, Bangalore', rating: 4.6, status: RestaurantStatus.pendingApproval, totalOrders: 0, totalRevenue: 0, walletBalance: 0, commissionRate: 0.10, transactions: []),
  AdminRestaurant(id: 'rst5', name: 'Taco Fiesta', cuisine: 'Mexican', location: 'BTM Layout, Bangalore', rating: 3.8, status: RestaurantStatus.disabled, totalOrders: 210, totalRevenue: 31500, walletBalance: 1800, commissionRate: 0.15, transactions: []),
  AdminRestaurant(id: 'rst6', name: 'Green Bowl', cuisine: 'Healthy, Salads', location: 'Jayanagar, Bangalore', rating: 4.4, status: RestaurantStatus.active, totalOrders: 540, totalRevenue: 81000, walletBalance: 4500, commissionRate: 0.09, transactions: []),
];

final List<AppUser> dummyUsers = [
  AppUser(id: 'usr1', name: 'Alex Johnson', email: 'alex@example.com', phone: '+91 98765 43210', status: UserStatus.active, totalOrders: 24, totalSpent: 7200, joinedAt: DateTime(2024, 3, 10)),
  AppUser(id: 'usr2', name: 'Priya Sharma', email: 'priya@example.com', phone: '+91 91234 56789', status: UserStatus.active, totalOrders: 18, totalSpent: 5400, joinedAt: DateTime(2024, 5, 22)),
  AppUser(id: 'usr3', name: 'Arjun Mehta', email: 'arjun@example.com', phone: '+91 98765 12345', status: UserStatus.blocked, totalOrders: 6, totalSpent: 1800, joinedAt: DateTime(2024, 8, 1)),
  AppUser(id: 'usr4', name: 'Sneha Patel', email: 'sneha@example.com', phone: '+91 87654 32109', status: UserStatus.active, totalOrders: 41, totalSpent: 12300, joinedAt: DateTime(2024, 1, 15)),
  AppUser(id: 'usr5', name: 'Karthik Raj', email: 'karthik@example.com', phone: '+91 76543 21098', status: UserStatus.active, totalOrders: 9, totalSpent: 2700, joinedAt: DateTime(2025, 1, 5)),
  AppUser(id: 'usr6', name: 'Divya Nair', email: 'divya@example.com', phone: '+91 65432 10987', status: UserStatus.active, totalOrders: 33, totalSpent: 9900, joinedAt: DateTime(2024, 6, 18)),
];

final List<AdminOrder> dummyOrders = [
  AdminOrder(id: 'ord1', customerId: 'usr1', customerName: 'Alex Johnson', restaurantId: 'rst1', restaurantName: 'Spice Garden', orderValue: 299, commissionRate: 0.10, status: OrderStatus.delivered, assignedDriverId: 'drv1', assignedDriverName: 'Ravi Kumar', placedAt: DateTime.now().subtract(const Duration(hours: 2)), items: ['Chicken Biryani x1', 'Garlic Naan x2'], paymentReleased: true, timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(hours: 2))),
    OrderTimelineEvent(label: 'Delivered', time: DateTime.now().subtract(const Duration(minutes: 50))),
  ]),
  AdminOrder(id: 'ord2', customerId: 'usr2', customerName: 'Priya Sharma', restaurantId: 'rst2', restaurantName: 'Burger Barn', orderValue: 249, commissionRate: 0.12, status: OrderStatus.preparing, assignedDriverId: 'drv4', assignedDriverName: 'Pradeep Nair', placedAt: DateTime.now().subtract(const Duration(minutes: 20)), items: ['Classic Smash Burger x2', 'Loaded Fries x1'], timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(minutes: 20))),
    OrderTimelineEvent(label: 'Preparing', time: DateTime.now().subtract(const Duration(minutes: 15))),
  ]),
  AdminOrder(id: 'ord3', customerId: 'usr4', customerName: 'Sneha Patel', restaurantId: 'rst3', restaurantName: 'Pizza Palace', orderValue: 379, commissionRate: 0.08, status: OrderStatus.outForDelivery, assignedDriverId: 'drv2', assignedDriverName: 'Suresh Babu', placedAt: DateTime.now().subtract(const Duration(minutes: 45)), items: ['BBQ Chicken Pizza x1', 'Tiramisu x1'], timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(minutes: 45))),
    OrderTimelineEvent(label: 'Out for Delivery', time: DateTime.now().subtract(const Duration(minutes: 10))),
  ]),
  AdminOrder(id: 'ord4', customerId: 'usr5', customerName: 'Karthik Raj', restaurantId: 'rst1', restaurantName: 'Spice Garden', orderValue: 199, commissionRate: 0.10, status: OrderStatus.pending, placedAt: DateTime.now().subtract(const Duration(minutes: 35)), items: ['Dal Makhani x1', 'Garlic Naan x3'], timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(minutes: 35))),
  ]),
  AdminOrder(id: 'ord5', customerId: 'usr6', customerName: 'Divya Nair', restaurantId: 'rst6', restaurantName: 'Green Bowl', orderValue: 448, commissionRate: 0.09, status: OrderStatus.pending, placedAt: DateTime.now().subtract(const Duration(minutes: 5)), items: ['Quinoa Power Bowl x2', 'Green Smoothie x2'], timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(minutes: 5))),
  ]),
  AdminOrder(id: 'ord6', customerId: 'usr3', customerName: 'Arjun Mehta', restaurantId: 'rst2', restaurantName: 'Burger Barn', orderValue: 178, commissionRate: 0.12, status: OrderStatus.cancelled, placedAt: DateTime.now().subtract(const Duration(hours: 5)), items: ['Veggie Delight Burger x1'], timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(hours: 5))),
    OrderTimelineEvent(label: 'Cancelled', time: DateTime.now().subtract(const Duration(hours: 4, minutes: 55))),
  ]),
  AdminOrder(id: 'ord7', customerId: 'usr1', customerName: 'Alex Johnson', restaurantId: 'rst3', restaurantName: 'Pizza Palace', orderValue: 299, commissionRate: 0.08, status: OrderStatus.delivered, assignedDriverId: 'drv1', assignedDriverName: 'Ravi Kumar', placedAt: DateTime.now().subtract(const Duration(days: 1)), items: ['Margherita Pizza x1', 'Pasta Arrabbiata x1'], paymentReleased: true, timeline: [
    OrderTimelineEvent(label: 'Order Placed', time: DateTime.now().subtract(const Duration(days: 1))),
    OrderTimelineEvent(label: 'Delivered', time: DateTime.now().subtract(const Duration(hours: 22))),
  ]),
];

final List<AdminAlert> dummyAlerts = [
  AdminAlert(id: 'a1', title: 'Delayed Order', description: 'Order #ord4 has been pending for over 30 minutes.', severity: AlertSeverity.high, type: AlertType.orderAlert, createdAt: DateTime.now().subtract(const Duration(minutes: 5)), orderId: 'ord4', customerName: 'Karthik Raj', restaurantName: 'Spice Garden', orderedItems: ['Dal Makhani x1', 'Garlic Naan x3']),
  AdminAlert(id: 'a2', title: 'New Order Placed', description: 'Divya Nair placed a new order at Green Bowl.', severity: AlertSeverity.low, type: AlertType.orderAlert, createdAt: DateTime.now().subtract(const Duration(minutes: 5)), orderId: 'ord5', customerName: 'Divya Nair', restaurantName: 'Green Bowl', orderedItems: ['Quinoa Power Bowl x2', 'Green Smoothie x2']),
  AdminAlert(id: 'a3', title: 'Customer Login', description: 'Alex Johnson logged in from a new device.', severity: AlertSeverity.low, type: AlertType.loginActivity, createdAt: DateTime.now().subtract(const Duration(minutes: 12)), customerName: 'Alex Johnson'),
  AdminAlert(id: 'a4', title: 'Restaurant Login', description: 'Spice Garden admin logged in.', severity: AlertSeverity.low, type: AlertType.loginActivity, createdAt: DateTime.now().subtract(const Duration(minutes: 30)), restaurantName: 'Spice Garden'),
  AdminAlert(id: 'a5', title: 'Driver Login', description: 'Ravi Kumar came online and is now available.', severity: AlertSeverity.low, type: AlertType.loginActivity, createdAt: DateTime.now().subtract(const Duration(hours: 1)), customerName: 'Ravi Kumar'),
  AdminAlert(id: 'a6', title: 'Driver Assigned', description: 'Suresh Babu was assigned to order #ord3.', severity: AlertSeverity.low, type: AlertType.systemEvent, createdAt: DateTime.now().subtract(const Duration(minutes: 25)), orderId: 'ord3'),
  AdminAlert(id: 'a7', title: 'Payment Released', description: 'Payout of Rs.5,000 released to Spice Garden.', severity: AlertSeverity.medium, type: AlertType.systemEvent, createdAt: DateTime.now().subtract(const Duration(days: 1)), restaurantName: 'Spice Garden'),
  AdminAlert(id: 'a8', title: 'New Restaurant Approval', description: 'Sushi Zen is awaiting approval.', severity: AlertSeverity.medium, type: AlertType.systemEvent, createdAt: DateTime.now().subtract(const Duration(hours: 6)), restaurantName: 'Sushi Zen'),
];

final List<ActivityFeedItem> dummyActivityFeed = [
  ActivityFeedItem(id: 'act1', type: ActivityType.orderPlaced, message: 'Divya Nair placed order at Green Bowl', time: DateTime.now().subtract(const Duration(minutes: 5))),
  ActivityFeedItem(id: 'act2', type: ActivityType.driverAssigned, message: 'Suresh Babu assigned to order #ord3', time: DateTime.now().subtract(const Duration(minutes: 10))),
  ActivityFeedItem(id: 'act3', type: ActivityType.loginCustomer, message: 'Alex Johnson logged in', time: DateTime.now().subtract(const Duration(minutes: 12))),
  ActivityFeedItem(id: 'act4', type: ActivityType.orderDelivered, message: 'Order #ord1 delivered to Alex Johnson', time: DateTime.now().subtract(const Duration(minutes: 50))),
  ActivityFeedItem(id: 'act5', type: ActivityType.loginRestaurant, message: 'Spice Garden admin logged in', time: DateTime.now().subtract(const Duration(minutes: 30))),
  ActivityFeedItem(id: 'act6', type: ActivityType.paymentReleased, message: 'Rs.5,000 payout released to Spice Garden', time: DateTime.now().subtract(const Duration(days: 1))),
  ActivityFeedItem(id: 'act7', type: ActivityType.orderDelayed, message: 'Order #ord4 delayed - no driver assigned', time: DateTime.now().subtract(const Duration(minutes: 5))),
  ActivityFeedItem(id: 'act8', type: ActivityType.loginDriver, message: 'Ravi Kumar came online', time: DateTime.now().subtract(const Duration(hours: 1))),
];

final List<DriverDailySummary> dummyDriverSummaries = [
  DriverDailySummary(driverId: 'drv1', date: DateTime.now(), totalOrders: 8, codOrders: 5, codAmount: 1240, onlineOrders: 3, onlineAmount: 720, submittedAmount: 1240, submissions: [
    CashSubmission(id: 'cs1', amount: 800, submittedAt: DateTime.now().subtract(const Duration(hours: 3)), note: 'Morning batch'),
    CashSubmission(id: 'cs2', amount: 440, submittedAt: DateTime.now().subtract(const Duration(hours: 1)), note: 'Evening batch'),
  ]),
  DriverDailySummary(driverId: 'drv2', date: DateTime.now(), totalOrders: 6, codOrders: 4, codAmount: 980, onlineOrders: 2, onlineAmount: 450, submittedAmount: 500, submissions: [
    CashSubmission(id: 'cs3', amount: 500, submittedAt: DateTime.now().subtract(const Duration(hours: 2)), note: 'Partial submission'),
  ]),
  DriverDailySummary(driverId: 'drv3', date: DateTime.now(), totalOrders: 4, codOrders: 3, codAmount: 670, onlineOrders: 1, onlineAmount: 199, submittedAmount: 0, submissions: []),
  DriverDailySummary(driverId: 'drv4', date: DateTime.now(), totalOrders: 10, codOrders: 6, codAmount: 1580, onlineOrders: 4, onlineAmount: 890, submittedAmount: 1580, submissions: [
    CashSubmission(id: 'cs4', amount: 1580, submittedAt: DateTime.now().subtract(const Duration(minutes: 30)), note: 'Full settlement'),
  ]),
  DriverDailySummary(driverId: 'drv5', date: DateTime.now(), totalOrders: 2, codOrders: 2, codAmount: 380, onlineOrders: 0, onlineAmount: 0, submittedAmount: 0, submissions: []),
];

final Map<String, List<DriverSettlementRecord>> dummySettlementHistory = {
  'drv1': [
    DriverSettlementRecord(driverId: 'drv1', date: DateTime.now(), ordersCompleted: 8, codCollected: 1240, submittedAmount: 1240),
    DriverSettlementRecord(driverId: 'drv1', date: DateTime.now().subtract(const Duration(days: 1)), ordersCompleted: 7, codCollected: 1050, submittedAmount: 1050),
    DriverSettlementRecord(driverId: 'drv1', date: DateTime.now().subtract(const Duration(days: 2)), ordersCompleted: 9, codCollected: 1380, submittedAmount: 1380),
  ],
  'drv2': [
    DriverSettlementRecord(driverId: 'drv2', date: DateTime.now(), ordersCompleted: 6, codCollected: 980, submittedAmount: 500),
    DriverSettlementRecord(driverId: 'drv2', date: DateTime.now().subtract(const Duration(days: 1)), ordersCompleted: 5, codCollected: 760, submittedAmount: 760),
  ],
  'drv3': [
    DriverSettlementRecord(driverId: 'drv3', date: DateTime.now(), ordersCompleted: 4, codCollected: 670, submittedAmount: 0),
    DriverSettlementRecord(driverId: 'drv3', date: DateTime.now().subtract(const Duration(days: 1)), ordersCompleted: 3, codCollected: 450, submittedAmount: 450),
  ],
  'drv4': [
    DriverSettlementRecord(driverId: 'drv4', date: DateTime.now(), ordersCompleted: 10, codCollected: 1580, submittedAmount: 1580),
    DriverSettlementRecord(driverId: 'drv4', date: DateTime.now().subtract(const Duration(days: 1)), ordersCompleted: 11, codCollected: 1720, submittedAmount: 1720),
  ],
  'drv5': [
    DriverSettlementRecord(driverId: 'drv5', date: DateTime.now(), ordersCompleted: 2, codCollected: 380, submittedAmount: 0),
    DriverSettlementRecord(driverId: 'drv5', date: DateTime.now().subtract(const Duration(days: 1)), ordersCompleted: 3, codCollected: 490, submittedAmount: 490),
  ],
};

final List<double> weeklyOrders = [38, 52, 45, 61, 58, 74, 67];
final List<double> weeklyRevenue = [9.2, 12.4, 10.8, 14.6, 13.9, 17.7, 16.1];

final List<Map<String, dynamic>> categoryData = [
  {'label': 'Biryani', 'value': 28.0, 'color': 0xFF16A34A},
  {'label': 'Burgers', 'value': 22.0, 'color': 0xFF4ADE80},
  {'label': 'Pizza', 'value': 18.0, 'color': 0xFF2563EB},
  {'label': 'Healthy', 'value': 14.0, 'color': 0xFFF59E0B},
  {'label': 'Others', 'value': 18.0, 'color': 0xFFE5E7EB},
];