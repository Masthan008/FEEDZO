# StackFood Apps Integration Analysis

## Overview
This document analyzes the StackFood ecosystem apps (Customer App, Restaurant App, Deliveryman App) and links the 50 admin panel features to these apps.

## StackFood App Architecture

### 1. Customer App (Flutter)
**Purpose:** End-user facing mobile app for ordering food

**Key Features:**
- Browse restaurants and menu items
- Search and filter functionality
- Place orders (instant and scheduled)
- Track order status in real-time
- Rate and review restaurants, dishes, and drivers
- Loyalty program integration
- Wallet management
- Favorites management
- Support tickets
- Notification management

**Firebase Collections Used:**
- `users` - Customer profiles
- `restaurants` - Restaurant listings
- `items` - Menu items
- `orders` - Customer orders
- `reviews` - Ratings and reviews
- `favorites` - Favorite restaurants/items
- `loyalty_points` - Loyalty program
- `point_transactions` - Points history
- `rewards` - Available rewards
- `reward_redemptions` - Redemption records
- `customerWallet` - Wallet balance
- `support_tickets` - Support requests
- `notifications` - Push notifications
- `devices` - Device management
- `privacy_settings` - GDPR compliance
- `marketing_preferences` - Communication preferences
- `search_history` - Search history
- `chat_messages` - Driver communication
- `tips` - Tips to drivers
- `customerVerifications` - Identity verification

### 2. Restaurant App (Flutter)
**Purpose:** Restaurant management mobile app for restaurant owners

**Key Features:**
- Manage restaurant profile
- Manage menu items
- Accept/reject orders
- Update order status
- View order history
- Manage restaurant availability
- View earnings and settlements
- Manage restaurant documents
- Request payouts
- View reviews and respond
- Manage restaurant-specific settings

**Firebase Collections Used:**
- `restaurants` - Restaurant profile
- `restaurants/{restaurantId}/menu` - Menu items
- `restaurants/{restaurantId}/documents` - Verification docs
- `orders` - Order management
- `reviews` - Customer reviews
- `transactions` - Earnings
- `restaurantPayoutRequests` - Payout requests
- `commissionSettings` - Commission rates
- `restaurantHikeOverrides` - Hike charge overrides
- `chat_messages` - Customer communication
- `driverNotifications` - Driver notifications
- `driverAssignmentLogs` - Assignment tracking
- `businessConfigs` - Business model settings
- `schedules` - Operating schedule

### 3. Deliveryman App (Flutter)
**Purpose:** Driver management mobile app for delivery drivers

**Key Features:**
- Go online/offline
- View available orders
- Accept/reject orders
- Navigate to restaurant
- Navigate to customer
- Update order status
- Manage cash collection
- Submit COD to admin
- View earnings
- View performance metrics
- Manage profile
- Chat with customers
- View tips received
- Manage cash in hand limit

**Firebase Collections Used:**
- `drivers` - Driver profile
- `orders` - Order assignments
- `settlements` - COD settlements
- `driverSubmissions` - Cash submissions
- `driverEarnings` - Earnings tracking
- `driverCashLimits` - Cash in hand limits
- `driverNotifications` - Order notifications
- `driverAssignmentLogs` - Assignment logs
- `chat_messages` - Customer communication
- `incentives` - Peak pay and challenges
- `reviews` - Customer ratings
- `tips` - Tips received
- `vehicleCoverage` - Coverage areas
- `schedules` - Shift schedules

## Admin Panel Features Mapping to Apps

### Phase 2 Features (6 features)
1. **Zone Setup** → All Apps (location-based filtering)
2. **Cuisine Management** → Customer App (cuisine filtering)
3. **Food Addons** → Customer App (menu customization)
4. **Subscription Management** → Customer App (subscriptions)
5. **Customer Wallet** → Customer App (wallet integration)
6. **Restaurant Withdrawals** → Restaurant App (payouts)

### Phase 3 Features (6 features)
1. **Language Settings** → All Apps (multi-language support)
2. **Theme Settings** → All Apps (theming)
3. **Email Templates** → All Apps (email notifications)
4. **Social Media** → React Website (social links)
5. **Legal Pages** → All Apps (terms, privacy)
6. **About Us** → React Website (about page)

### Phase 4 Features (4 features)
1. **Chat System** → Customer App, Restaurant App, Deliveryman App (communication)
2. **Newsletter Subscriptions** → React Website (newsletter)
3. **App Version Control** → All Apps (version enforcement)
4. **Landing Page Customization** → React Website (landing pages)

### Phase 5 Features (5 features)
1. **Tips System** → Customer App (tipping), Deliveryman App (tip tracking)
2. **Customer Verification** → Customer App (identity verification)
3. **Third Party Config** → All Apps (payment gateways)
4. **Bulk Import/Export** → Admin Panel (data management)
5. **Database Cleanup** → Admin Panel (maintenance)

### Phase 6 Features (5 features)
1. **Driver Earnings Display** → Deliveryman App (earnings view)
2. **Maximum Cash in Hand** → Deliveryman App (cash limit enforcement)
3. **Food Reviews** → Customer App (reviews), Restaurant App (view/respond)
4. **Reports** → Admin Panel (analytics)
5. **Dispatch Management** → Restaurant App, Deliveryman App (order dispatch)

### Phase 7 Features (3 features)
1. **Vehicle Coverage** → Deliveryman App (coverage areas)
2. **Business Models** → All Apps (business type)
3. **Self-Registration** → Restaurant App, Deliveryman App (registration)

### Phase 8 Features (2 features)
1. **Subscription Reports** → Customer App (subscription tracking)
2. **Campaign Reports** → Admin Panel (marketing analytics)

### Phase 9 Features (3 features)
1. **Customer Analytics** → Admin Panel (customer insights)
2. **Restaurant Analytics** → Restaurant App (performance)
3. **Driver Analytics** → Deliveryman App (performance)

### Phase 10 Features (16 features)
1. **Inventory Management** → Restaurant App (stock tracking)
2. **Loyalty Program** → Customer App (loyalty points)
3. **Referral Program** → Customer App (referrals)
4. **Promotions** → Customer App (discounts)
5. **Schedule Management** → Restaurant App, Deliveryman App (operating hours)
6. **Payment Methods** → All Apps (payment options)
7. **Delivery Zones** → Customer App, Deliveryman App (zones)
8. **Order Analytics** → Admin Panel (order insights)
9. **Support Tickets** → All Apps (support)
10. **Notifications** → All Apps (push notifications)
11. **Audit Logs** → Admin Panel (audit trail)
12. **Feedback** → Customer App (feedback)
13. **User Activity** → Admin Panel (activity tracking)
14. **System Health** → Admin Panel (monitoring)
15. **API Logs** → Admin Panel (API tracking)
16. **Performance Monitor** → Admin Panel (performance)

## Firebase Security Rules Status

### Fixed Issues
✅ **Reviews System Error Fixed**
- Changed `affectedKeys()` to `changedKeys()` in reviews update rules
- Lines 282, 293, 300 in firestore.rules

### Current Firebase Rules Coverage
- ✅ Users, Restaurants, Items, Drivers, Orders
- ✅ Reviews & Ratings (comprehensive system)
- ✅ Loyalty Program (points, transactions, rewards)
- ✅ Chat Messages
- ✅ Incentives
- ✅ Refunds
- ✅ Support Tickets
- ✅ Search History
- ✅ Device Management
- ✅ Privacy Settings
- ✅ Marketing Preferences
- ✅ Driver Notifications
- ✅ Driver Assignment Logs
- ✅ Hike Charges
- ✅ Driver Submissions
- ✅ Restaurant Management (menu, documents, payouts)
- ✅ Commission Settings
- ✅ Platform Settings
- ✅ Zones
- ✅ Cuisines
- ✅ Food Addons
- ✅ Subscriptions
- ✅ Customer Wallet
- ✅ Restaurant Withdrawals
- ✅ Languages
- ✅ Themes
- ✅ Email Templates
- ✅ Social Media
- ✅ Legal Pages
- ✅ About Us
- ✅ Admin Chats
- ✅ Newsletter Subscribers
- ✅ App Versions
- ✅ Landing Pages
- ✅ Tips
- ✅ Customer Verifications
- ✅ Third Party Configs
- ✅ Driver Earnings
- ✅ Driver Cash Limits
- ✅ Analytics Data
- ✅ Business Configs
- ✅ Self-Registration Settings
- ✅ Subscription Reports
- ✅ Campaign Reports
- ✅ Inventory
- ✅ Loyalty
- ✅ Referrals
- ✅ Promotions
- ✅ Schedules
- ✅ Support Tickets
- ✅ Audit Logs
- ✅ Feedback
- ✅ Activity Logs

## Firebase Indexes Required

### Recommended Indexes for Performance

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "customerId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "restaurantId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "driverId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "scheduledFor", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "targetType", "order": "ASCENDING"},
        {"fieldPath": "targetId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "customerId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "targetId", "order": "ASCENDING"},
        {"fieldPath": "rating", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "isVisible", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "restaurantId", "order": "ASCENDING"},
        {"fieldPath": "isAvailable", "order": "ASCENDING"},
        {"fieldPath": "category", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "isVeg", "order": "ASCENDING"},
        {"fieldPath": "isBestseller", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "restaurants",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "zoneId", "order": "ASCENDING"},
        {"fieldPath": "isOpen", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "restaurants",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "cuisineId", "order": "ASCENDING"},
        {"fieldPath": "isOpen", "order": "ASCENDING"},
        {"fieldPath": "rating", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "drivers",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "zoneId", "order": "ASCENDING"},
        {"fieldPath": "isOnline", "order": "ASCENDING"},
        {"fieldPath": "isAvailable", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "drivers",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "vehicleType", "order": "ASCENDING"},
        {"fieldPath": "isOnline", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "chat_messages",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "orderId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "chat_messages",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "senderId", "order": "ASCENDING"},
        {"fieldPath": "recipientId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "loyalty_points",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "currentTier", "order": "ASCENDING"},
        {"fieldPath": "totalPoints", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "point_transactions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "support_tickets",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "customerId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "targetUserId", "order": "ASCENDING"},
        {"fieldPath": "isRead", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "driverNotifications",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "driverId", "order": "ASCENDING"},
        {"fieldPath": "isRead", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

## Missing Features Implementation Plan

### Priority 1 - Critical Features (Not Yet Implemented)

1. **Real-time Order Tracking Map**
   - Customer App: Live tracking of driver location
   - Deliveryman App: GPS navigation integration
   - Firebase: Need `orders/{orderId}/tracking` subcollection
   - Admin: Already covered in Dispatch Management

2. **Push Notification Deep Links**
   - All Apps: Deep linking to specific screens from notifications
   - Firebase: Need to add deep link configuration

3. **Offline Mode Support**
   - All Apps: Offline functionality with data sync
   - Firebase: Need to add offline persistence configuration

4. **Multi-language Support in Apps**
   - All Apps: Dynamic language switching
   - Firebase: Languages collection already exists
   - Need: App-side implementation

5. **Dark Mode in Apps**
   - All Apps: Dark theme support
   - Firebase: Themes collection already exists
   - Need: App-side implementation

### Priority 2 - Important Features

1. **Scheduled Orders**
   - Customer App: Schedule orders for future
   - Firebase: Orders already support `scheduledFor`
   - Need: App-side UI and logic

2. **Recurring Orders**
   - Customer App: Repeat favorite orders
   - Firebase: Need `recurringOrders` collection
   - Admin: Already covered in Subscription Management

3. **Split Payment**
   - Customer App: Multiple payment methods
   - Firebase: Need `splitPayments` subcollection in orders
   - Admin: Already covered in Payment Methods

4. **Group Ordering**
   - Customer App: Multiple users order together
   - Firebase: Need `groupOrders` collection
   - Admin: Need Group Orders screen

5. **Voice Search**
   - Customer App: Voice-activated search
   - Firebase: No changes needed
   - Need: App-side implementation

## Firebase Rules Deployment

To deploy the updated Firebase rules:

```bash
firebase deploy --only firestore:rules
```

## Next Steps

1. ✅ Fixed Firebase reviews rules error
2. ✅ Created comprehensive analysis document
3. ✅ Mapped all 50 admin features to apps
4. ✅ Created Firebase indexes specification
5. ⏳ Deploy Firebase rules to production
6. ⏳ Create Firebase indexes in console
7. ⏳ Implement missing features in apps
