# 🏪 Admin Restaurant Management - Feature Implementation Plan

## Executive Summary

This document outlines the comprehensive restaurant management features for the Feedzo Admin Panel, including analysis of existing features and new enhancements needed.

---

## 📊 Current State Analysis

### ✅ EXISTING FEATURES (Already Implemented)

#### Admin Panel (`feedzo_admin`)
1. **Restaurant List View** (`restaurants_screen.dart`)
   - View all restaurants from Firestore
   - Shows: Name, Email, Status (Active/Pending), Commission %, Wallet Balance
   - Pending approval banner for new restaurants
   
2. **Approval System** (Basic)
   - Approve/Reject pending restaurants
   - Updates `isApproved` flag and user status
   
3. **Commission Management**
   - Inline editing of commission percentage
   - Range: 0-50%
   
4. **Wallet/Payout Management**
   - View wallet balance per restaurant
   - Release payout button
   - Creates transaction record

#### Restaurant App (`feedzo_restaurant_app`)
1. **Menu Management** (`menu_screen.dart`)
   - Full CRUD for menu items
   - Fields: name, description, price, discount, isAvailable, image, isVeg, category, isBestseller
   - Cloudinary image upload
   
2. **Restaurant Status**
   - Waiting approval screen for new registrations
   - No open/close toggle currently

### ❌ MISSING FEATURES (To Implement)

| Feature | Priority | Est. Time | Description |
|---------|----------|-----------|-------------|
| **Add/Edit/Delete Restaurant** | HIGH | 4 hours | Full CRUD operations in admin |
| **Menu Management (Admin)** | HIGH | 6 hours | Admin can manage any restaurant's menu |
| **Enhanced Approval Workflow** | HIGH | 3 hours | Approval with rejection reason, documents |
| **Open/Close Toggle** | HIGH | 2 hours | Real-time restaurant status toggle |
| **Commission Settings** | MEDIUM | 2 hours | Already partially done, needs enhancement |
| **Restaurant Details View** | MEDIUM | 3 hours | Comprehensive restaurant profile view |
| **Document Verification** | MEDIUM | 4 hours | FSSAI, GST, PAN upload and verification |
| **Category Management** | LOW | 3 hours | Admin can create/manage food categories |

---

## 🎯 Feature Implementation Plan

### 1. ENHANCED RESTAURANT CRUD OPERATIONS

#### Current Gaps:
- Admin can only view restaurants, not create/edit/delete
- No detailed restaurant profile view

#### Implementation:
**New Files:**
- `lib/screens/restaurants/restaurant_detail_screen.dart` - Full restaurant profile
- `lib/screens/restaurants/restaurant_form_dialog.dart` - Add/Edit restaurant form
- `lib/services/restaurant_admin_service.dart` - CRUD operations

**Features:**
- Create new restaurant (bypass registration flow)
- Edit restaurant details: name, email, phone, address, cuisine type
- Delete restaurant (with confirmation)
- View complete restaurant profile
- Upload/change restaurant image

**Data Model Updates:**
```dart
class AdminRestaurant {
  // Existing fields...
  String phone;
  String address;
  GeoPoint? location;
  String? fssaiNumber;
  String? gstNumber;
  String? panNumber;
  List<String> documents;
  bool isOpen;  // NEW: Open/Close status
  String? rejectionReason;  // NEW: For rejected restaurants
  DateTime? approvedAt;  // NEW: Approval timestamp
}
```

---

### 2. MENU MANAGEMENT SYSTEM (Admin Override)

#### Current State:
- Restaurant app has full menu management
- Admin has NO menu management capabilities

#### Implementation:
**New Files:**
- `lib/screens/restaurants/menu_management_screen.dart` - Admin menu view
- `lib/screens/restaurants/menu_item_dialog.dart` - Add/Edit menu item
- `lib/widgets/menu_item_card.dart` - Reusable menu item widget

**Features:**
- Access any restaurant's menu
- Add/Edit/Delete menu items on behalf of restaurant
- Toggle item availability (enable/disable)
- Bulk operations (price updates, category changes)
- View menu analytics (most ordered items)

**Firestore Structure:**
```
restaurants/{restaurantId}/
  └── menu/{itemId} - Menu items subcollection
```

---

### 3. RESTAURANT APPROVAL WORKFLOW

#### Current State:
- Basic approve/reject buttons
- No rejection reasons
- No document verification

#### Enhancement Plan:
**Updates to:** `lib/screens/restaurants_screen.dart`

**Features:**
- View submitted documents (FSSAI, GST, PAN)
- Approve with optional notes
- Reject with mandatory reason
- Email notification to restaurant
- Approval history/audit log

**New Fields in Firestore:**
```javascript
{
  isApproved: boolean,
  approvalStatus: 'pending' | 'approved' | 'rejected',
  rejectionReason: string,
  approvedAt: timestamp,
  approvedBy: string,
  documents: {
    fssai: { url: string, verified: boolean },
    gst: { url: string, verified: boolean },
    pan: { url: string, verified: boolean }
  }
}
```

---

### 4. OPEN/CLOSE TOGGLE

#### Current State:
- No open/close functionality exists

#### Implementation:
**Updates to:** 
- `lib/screens/restaurants_screen.dart` - Toggle button in actions
- `lib/screens/restaurants/restaurant_detail_screen.dart` - Toggle in details

**Features:**
- Quick toggle button in restaurant list
- Scheduled open/close times (optional)
- Auto-close at specified time
- "Temporarily Closed" mode
- Customer app sees real-time status

**Firestore Field:**
```javascript
{
  isOpen: boolean,
  autoOpenClose: {
    enabled: boolean,
    openTime: string, // "09:00"
    closeTime: string, // "22:00"
    daysOpen: [1,2,3,4,5,6,7] // Monday=1
  }
}
```

---

### 5. COMMISSION SETTINGS PER RESTAURANT

#### Current State:
- Basic commission % editing exists
- No tiered commission structure

#### Enhancement:
**Features:**
- Base commission rate (already exists)
- Tiered commission (based on order volume)
- Special commission for promotions
- Commission history/changelog

**Commission Tiers Example:**
```javascript
{
  commission: {
    baseRate: 10, // 10%
    tiers: [
      { minOrders: 0, maxOrders: 100, rate: 10 },
      { minOrders: 101, maxOrders: 500, rate: 8 },
      { minOrders: 501, rate: 6 }
    ],
    specialRate: null, // Override for promos
    specialRateExpiry: null
  }
}
```

---

## 🔗 Integration with Restaurant App

### Changes Required in `feedzo_restaurant_app`:

1. **Listen to `isOpen` status**
   - Update `dashboard_screen.dart` to show open/close status
   - Add toggle in restaurant profile
   
2. **Approval Status Handling**
   - Update `waiting_approval_screen.dart` to show rejection reasons
   - Show "Rejected" status with re-apply option
   
3. **Menu Sync**
   - Already real-time via Firestore
   - Admin changes reflect immediately

4. **Commission Display**
   - Show current commission rate in wallet/earnings

---

## 🔒 Firestore Security Rules

### New Rules Needed:

```javascript
// Restaurant management - Admin only
match /restaurants/{restaurantId} {
  allow read: if isAuth();
  allow create: if isAdmin();
  allow update: if isAdmin() || 
    (isRestaurant() && resource.data.id == uid() && 
     request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['isOpen', 'autoOpenClose'])); // Restaurant can only toggle open/close
  allow delete: if isAdmin();
}

// Menu items - Admin or Restaurant owner
match /restaurants/{restaurantId}/menu/{itemId} {
  allow read: if isAuth();
  allow create: if isAdmin() || isRestaurantOwner(restaurantId);
  allow update: if isAdmin() || isRestaurantOwner(restaurantId);
  allow delete: if isAdmin() || isRestaurantOwner(restaurantId);
}

// Restaurant documents - Admin only write
match /restaurantDocuments/{restaurantId} {
  allow read: if isAuth();
  allow write: if isAdmin();
}
```

---

## 📱 UI/UX Specifications

### Restaurant List Screen Enhancements:

```
┌─────────────────────────────────────────────────────────────┐
│  Restaurants                                    [+ Add New] │
│  Manage all partner restaurants                             │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search...          [Filters ▼]       Export    Refresh │
├─────────────────────────────────────────────────────────────┤
│  ⚠️ 3 Pending Approvals                                    │
│  Spice Garden, Biryani House, Pizza Corner                  │
│  [Approve Spice Garden] [Approve Biryani] [Approve Pizza]  │
├─────────────────────────────────────────────────────────────┤
│  Restaurant    Status    Commission   Wallet    Actions      │
├─────────────────────────────────────────────────────────────┤
│  🍕 Pizza Hut   ● Open   12%          ₹45,000   [View] [✏️] │
│  🍔 Burger King ● Open   10%          ₹23,500   [View] [✏️] │
│  🌶️ Spice Gard  ○ Closed 15%          ₹12,000   [View] [✏️] │
│  ⏳ Biryani Hou  Pending  10%          ₹0       [Approve]   │
└─────────────────────────────────────────────────────────────┘
```

### Restaurant Detail Screen:

```
┌─────────────────────────────────────────────────────────────┐
│  ← Pizza Hut                                    [Edit] [🗑️] │
├─────────────────────────────────────────────────────────────┤
│  🍕                    │  Status: ● Open                      │
│  Pizza Hut             │  [Close Restaurant]                  │
│  pizzahut@email.com    │                                      │
│  ★ 4.5 (230 reviews)   │  Documents:                         │
│                        │  ✅ FSSAI  ✅ GST  ⚠️ PAN (pending) │
├─────────────────────────────────────────────────────────────┤
│  📊 Quick Stats                                             │
│  ─────────────────────────────────────────────────────────  │
│  Total Orders: 1,234   Revenue: ₹8.5L   Commission: ₹85K   │
│  Wallet: ₹45,000     [Release Payout]                       │
├─────────────────────────────────────────────────────────────┤
│  📋 Menu Management (45 items)                  [+ Add Item] │
│  ─────────────────────────────────────────────────────────  │
│  Margherita Pizza    ₹299    ● Available   [✏️] [🗑️]        │
│  Pepperoni Pizza     ₹399    ● Available   [✏️] [🗑️]        │
│  Veggie Supreme      ₹349    ○ Unavailable [✏️] [🗑️]        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗓️ Implementation Timeline

### Phase 1: Core CRUD (Day 1-2)
- [ ] Restaurant detail screen
- [ ] Add/Edit/Delete restaurant form
- [ ] Restaurant service layer

### Phase 2: Menu Management (Day 2-3)
- [ ] Menu management screen
- [ ] Menu item CRUD operations
- [ ] Bulk operations

### Phase 3: Approval & Status (Day 3)
- [ ] Enhanced approval workflow
- [ ] Open/Close toggle
- [ ] Document verification UI

### Phase 4: Integration & Rules (Day 4)
- [ ] Update Firestore rules
- [ ] Sync with restaurant app
- [ ] Testing & debugging

### Phase 5: Deploy (Day 4-5)
- [ ] Build admin web
- [ ] Deploy to hosting
- [ ] Verify in production

---

## 🎯 Success Metrics

1. **Admin can:**
   - Create a new restaurant in < 2 minutes
   - Manage any restaurant's menu without app access
   - Approve/reject with proper audit trail
   - Toggle restaurant open/close in real-time

2. **Restaurant sees:**
   - Immediate reflection of admin changes
   - Clear approval/rejection status with reasons
   - Open/close status synced across all apps

3. **Security:**
   - Only admins can modify other restaurants' data
   - Restaurants can only toggle their own open/close status
   - All admin actions are logged

---

## 🚀 Next Steps

1. ✅ **Review and approve this plan**
2. Start **Phase 1: Core CRUD** implementation
3. Implement features incrementally
4. Test thoroughly before deployment
5. Deploy and monitor

---

*Plan created: April 8, 2026*
*Target completion: 4-5 days*
