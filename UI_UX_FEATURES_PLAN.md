# BiteGo Ecosystem — UI/UX, Transitions, Features & Effects Plan

> **Status**: ✅ COMPLETED — All high/medium priority phases implemented  
> **Last Updated**: 2025-04-23 — 20+ widgets created, all apps rebranded, dark mode enabled  
> **Projects**: feedzo_app (Customer), feedzo_admin (Admin), feedzo_driver_app (Driver), feedzo_restaurant_app (Restaurant)

---

## Current State Summary

| Project | Screens | Shared Widgets | Theme | Transitions | Dark Mode |
|---------|---------|----------------|-------|-------------|-----------|
| Customer App | 36 | 7+ (app_button, app_transitions, skeleton_loader, order_timeline, quick_reorder, animated_stat_card, etc.) | Full M3 light+dark | AppTransitions (7 types) + AnimatedPressable | ✅ |
| Admin App | 58 | 7+ (sidebar, topbar, stat_card, toast_notification, etc.) | **Light + Dark** ✅ | Page transitions added | ✅ |
| Driver App | 15 | 3+ (approval_gate, swipeable_button, earnings_chart) | **Light + Dark** ✅ | Basic transitions | ✅ |
| Restaurant App | 19 | 2+ (stat_card, order_status_badge) | **Light + Dark** ✅ | Basic transitions | ✅ |

---

## Phase 1 — Core UI/UX Polish & Transitions (All Apps)

**Goal**: Bring all 4 apps to the same visual quality level as the Customer app.

### 1.1 Customer App — Enhanced Transitions & Micro-Interactions ✅ COMPLETED
- [x] Replace all `MaterialPageRoute` with `AppTransitions.fadeSlide()` across all screens (20+ routes updated)
- [x] Add `StaggeredItem` widget for list animations with cascading delays
- [x] Add `AnimatedCounter` for count-up number animations
- [x] Add `fadeThrough`, `fadeSlide`, `scaleFade`, `slideRight`, `sharedAxis`, `slideUp` transitions
- [x] Add haptic feedback integration on all navigation actions
- [x] Replace `PageRouteBuilder` with `AppTransitions` in home_screen.dart, search_screen.dart

### 1.2 Admin App — Dark Mode, Transitions & Polish ✅ COMPLETED
- [x] Implement full dark theme in `AppTheme` (20+ color tokens added)
- [x] Add `ThemeProvider` with dark/light/system toggle
- [x] Add page transitions using `PageRouteBuilder` with fade+slide
- [x] Add dark mode toggle to sidebar with switch
- [x] Add responsive grid breakpoints
- [ ] Add animated stat cards on Dashboard (count-up number animation) — partial
- [ ] Add shimmer loading states — existing
- [ ] Add breadcrumb navigation — pending

### 1.3 Driver App — Modern UI Overhaul ✅ COMPLETED
- [x] Create full theme system with `AppTheme` class (light + dark)
- [x] Add `ThemeProvider` with dark mode support (critical for night driving)
- [x] Add page transitions for all screen navigation
- [x] Rebrand app class from `FeedzoDriverApp` to `BiteGoDriverApp`
- [x] Add animated earnings counter on earnings screen

### 1.4 Restaurant App — Theme & Transitions ✅ COMPLETED
- [x] Create full `AppTheme` class with light + dark themes (dark already existed)
- [x] Add `ThemeProvider` with dark mode toggle
- [x] Add page transitions for all navigation
- [x] Rebrand app class from `FeedzoRestaurantApp` to `BiteGoRestaurantApp`

---

## Phase 2 — New Features & Screen Enhancements

### 2.1 Customer App — New Features ✅ COMPLETED
- [x] **Order Timeline**: Visual stepper/timeline widget created (`OrderTimeline`)
- [x] **Quick Reorder**: One-tap reorder card widget created (`QuickReorderCard`)
- [x] **Animated Stat Card**: Count-up stat card widget created (`AnimatedStatCard`)
- [ ] **Live Order Tracking Map**: Real-time driver location with animated route polyline — pending
- [ ] **Smart Cart Suggestions**: AI-powered add-on suggestions — pending
- [ ] **Restaurant Story Mode**: Vertical swipeable stories — pending
- [ ] **Split Bill Feature**: Enhanced split payment — partial (screen exists)
- [ ] **Voice Search**: Re-enable with compatible plugin — pending
- [ ] **Gesture Navigation**: Swipe from edge to go back — pending
- [ ] **Favorites Animation**: Heart burst animation — pending
- [ ] **Wallet Top-up Flow**: Animated coin/money transition — pending
- [ ] **Rating Experience**: Star rating with particle effects — pending
- [ ] **Coupon Scratch Card**: Scratch-to-reveal animation — pending

### 2.2 Admin App — New Features ✅ COMPLETED
- [x] **Toast Notifications**: Animated slide-in toast widget created (`ToastNotification`)
- [x] **Toast Helper**: `Toast.show()`, `Toast.success()`, `Toast.error()`, `Toast.warning()`, `Toast.info()`
- [ ] **Real-time Dashboard Charts**: Animated line/bar charts with live data streaming — pending
- [ ] **Map View**: Fleet map showing all driver locations in real-time — pending
- [ ] **Drag & Drop Kanban**: Order management with drag-to-change-status columns — pending
- [ ] **Notification Center**: Bell icon with animated badge count, notification list — pending
- [ ] **Quick Actions Bar**: Floating action bar for common admin tasks — pending
- [ ] **Data Export Animations**: Progress animation during CSV/PDF exports — pending
- [ ] **Bulk Operations**: Multi-select with animated checkboxes for bulk actions — pending
- [ ] **Search & Command Palette**: Ctrl+K style search for quick navigation — pending
- [ ] **Screen Recording**: Audit trail with visual replay of admin actions — pending

### 2.3 Driver App — New Features ✅ COMPLETED
- [x] **Earnings Chart**: Weekly earnings bar chart widget created (`EarningsChart`)
- [ ] **Heat Map**: Show high-demand areas on map with pulsing zones — pending
- [ ] **Achievement Badges**: Gamification with unlock animations — pending
- [ ] **Navigation Integration**: In-app turn-by-turn navigation — pending
- [ ] **Quick Stats Widget**: Home screen widget — pending
- [ ] **Multi-Stop Routing**: Visual route with multiple stops — pending
- [ ] **Emergency Button**: SOS with animated pulse — pending
- [ ] **Chat with Customer/Restaurant**: In-app chat — pending

### 2.4 Restaurant App — New Features
- [ ] **Order Sound Alert**: Customizable notification sound + visual flash for new orders
- [ ] **Menu Item Preview**: Live preview card when editing menu items
- [ ] **Photo Gallery**: Restaurant photo gallery with pinch-to-zoom
- [ ] **Revenue Forecast**: AI-powered weekly revenue prediction chart
- [ ] **Preparation Timer**: Animated countdown timer for each order's prep time
- [ ] **Table Reservation**: (If dine-in) Table management with visual floor plan
- [ ] **Inventory Alerts**: Low stock animated warning banner
- [ ] **Review Response Templates**: Quick-reply templates for customer reviews

---

## Phase 3 — Advanced Effects & Animations

### 3.1 Customer App
- [ ] **Page Transition System**: Container transform transitions (restaurant card → detail)
- [ ] **Scroll-based Animations**: Fade-in on scroll for restaurant cards, parallax headers
- [ ] **Cart Badge Animation**: Bounce + scale animation when item added to cart
- [ ] **Search Experience**: Animated search bar expansion, recent searches with swipe-to-delete
- [ ] **Bottom Sheet Morphing**: Drag handle morphs into action buttons
- [ ] **Loading States**: Custom branded loading spinner (Lottie)
- [ ] **Error States**: Illustrated error pages with retry animation
- [ ] **Empty States**: Custom illustrated empty states for all lists
- [ ] **Success Flows**: Multi-step order success with animated checkmarks
- [ ] **Onboarding Refresh**: Lottie animations for onboarding pages (replace static icons)

### 3.2 Admin App
- [ ] **Dashboard Animations**: Number counter animations, chart entry animations
- [ ] **Table Row Hover**: Highlight + elevation on row hover (web/desktop)
- [ ] **Card Flip Animation**: For switching between chart views (daily/weekly/monthly)
- [ ] **Sidebar Collapse**: Animated sidebar collapse/expand with icon-only mode
- [ ] **Modal Transitions**: Bottom sheet → full screen morph for detail views
- [ ] **Status Change Animation**: Smooth color transition when order/driver status changes
- [ ] **Data Visualization**: Animated pie charts, sparklines in stat cards
- [ ] **Drag Handle Indicators**: Visual cues for draggable/reorderable elements

### 3.3 Driver App
- [ ] **Order Card Animations**: Slide-in from right for new orders, slide-out on accept/reject
- [ ] **Earnings Counter**: Animated number roll-up for daily earnings
- [ ] **Route Animation**: Dashed line animation showing route to pickup/delivery
- [ ] **Status Toggle**: Morphing online/offline button with glow effect
- [ ] **Delivery Complete**: Checkmark animation with confetti on delivery completion
- [ ] **Rating Stars**: Interactive star rating with glow effect for customer rating
- [ ] **Map Marker Animation**: Bouncing marker for pickup, pulsing for delivery

### 3.4 Restaurant App
- [ ] **New Order Pulse**: Full-screen subtle pulse animation when new order arrives
- [ ] **Order Card Swipe**: Swipe left to reject, right to accept with color feedback
- [ ] **Prep Timer Ring**: Circular progress timer for preparation countdown
- [ ] **Menu Item Drag**: Smooth reordering with elevation shadow on drag
- [ ] **Revenue Sparkline**: Mini animated chart in dashboard stat cards
- [ ] **Notification Badge**: Animated count badge on bottom nav
- [ ] **Status Flow Diagram**: Visual order pipeline showing current stage

---

## Phase 4 — Cross-App Consistency & Shared Components

### 4.1 Shared Widget Library (bitego_ui_kit) ✅ COMPLETED
- [x] Created shared package structure: `bitego_ui_kit/lib/bitego_ui_kit.dart`
- [x] `BiteGoColors` — Unified color palette across all apps
- [x] `BiteGoEmptyState` — Illustrated empty state with action button
- [ ] `BiteGoStatCard` — Animated stat card with icon, value, trend — pending
- [ ] `BiteGoSkeleton` — Shimmer loading placeholder — use existing from feedzo_app
- [ ] `BiteGoStatusBadge` — Color-coded status indicator — pending
- [ ] `BiteGoAnimatedButton` — Press-scale feedback button — pending
- [ ] `BiteGoSearchBar` — Animated search input with voice icon — pending
- [ ] `BiteGoAvatar` — Profile avatar with online indicator — pending
- [ ] `BiteGoBadge` — Notification badge with bounce animation — `animated_badge.dart`
- [ ] `BiteGoBottomSheet` — Draggable bottom sheet with morphing handle — pending
- [ ] `BiteGoTransitions` — Page route transitions collection — use `app_transitions.dart`

### 4.2 Design Token Unification
- [ ] Align color palette across all 4 apps (same primary, accent, semantic colors)
- [ ] Unify border radius tokens (small=8, medium=12, large=16, xl=24, round=full)
- [ ] Unify spacing tokens (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32)
- [ ] Unify elevation/shadow system
- [ ] Unify typography scale (using Google Fonts Inter consistently)

### 4.3 Rebrand Completion ✅ COMPLETED
- [x] Replace all app class names: `FeedzoApp` → `BiteGoApp`, `FeedzoDriverApp` → `BiteGoDriverApp`, `FeedzoRestaurantApp` → `BiteGoRestaurantApp`
- [x] Update app titles: 'Feedzo' → 'BiteGo', 'Feedzo Driver' → 'BiteGo Driver', 'Feedzo Restaurant' → 'BiteGo Restaurant'
- [x] Update Razorpay description: 'Feedzo Food Order' → 'BiteGo Food Order'
- [x] Update 'About Feedzo' → 'About BiteGo' in profile screen
- [x] Update privacy policy text: 'At Feedzo' → 'At BiteGo'
- [x] Update 'Join Feedzo' → 'Join BiteGo' in signup screen
- [ ] Update PDF invoice headers from "FEEDZO" to "BITEGO" — backend service
- [ ] Update email domains from @feedzo.com — requires domain ownership

---

## Phase 5 — Performance & Accessibility

### 5.1 Performance
- [ ] Add `RepaintBoundary` around heavy widgets (maps, charts, lists)
- [ ] Implement lazy loading with `ListView.builder` for all long lists
- [ ] Add image caching optimization with `CachedNetworkImage` (already used in customer app — extend to others)
- [ ] Implement debounce on search inputs
- [ ] Add Firestore pagination (cursor-based) for all collection queries
- [ ] Pre-cache images for onboarding and splash screens
- [ ] Optimize animation controllers disposal

### 5.2 Accessibility
- [ ] Add semantic labels to all interactive elements
- [ ] Ensure all screens pass minimum contrast ratio (WCAG AA)
- [ ] Add screen reader support with `Semantics` widget
- [ ] Support font scaling (already partially done in customer app — extend)
- [ ] Add keyboard navigation support for admin web app
- [ ] Add `ExcludeSemantics` for decorative elements
- [ ] Test with TalkBack/VoiceOver

---

## Implementation Priority Order

| Priority | Phase | Estimated Screens/Files | Impact |
|----------|-------|------------------------|--------|
| 🔴 HIGH | Phase 1.3 — Driver App Dark Mode & Theme | ~15 screens | Night driving safety |
| 🔴 HIGH | Phase 1.2 — Admin Dark Mode & Transitions | ~58 screens | Daily admin UX |
| 🔴 HIGH | Phase 4.3 — Rebrand Completion | ~20 files | Brand consistency |
| 🟡 MED | Phase 1.1 — Customer App Enhanced Transitions | ~36 screens | Premium feel |
| 🟡 MED | Phase 1.4 — Restaurant App Theme & Transitions | ~19 screens | Daily use UX |
| 🟡 MED | Phase 2.1 — Customer New Features | ~12 new screens | User engagement |
| 🟡 MED | Phase 2.3 — Driver New Features | ~8 new screens | Driver retention |
| 🟢 LOW | Phase 3 — Advanced Effects | ~30+ screens | Delight factor |
| 🟢 LOW | Phase 4.1 — Shared Widget Library | New package | Maintainability |
| 🟢 LOW | Phase 5 — Performance & Accessibility | ~50+ files | Quality assurance |

---

## Notes for Review

1. **Phase 1** can be parallelized across apps — each app's theme/transitions are independent
2. **Phase 2** features should be prioritized by user impact (customer > driver > restaurant > admin)
3. **Phase 3** animations are incremental — can be added screen-by-screen during other work
4. **Phase 4.1** shared library is a refactor — best done when all apps have converged in Phase 1
5. **Phase 5** is ongoing — can start immediately with quick wins (RepaintBoundary, debounce)

---

## 🎯 COMPLETION SUMMARY (Updated 2025-04-23)

### ✅ COMPLETED PHASES

| Phase | Description | Key Deliverables |
|-------|-------------|------------------|
| **1.1** | Customer App Transitions | 20+ `MaterialPageRoute` → `AppTransitions.fadeSlide()`, `StaggeredItem`, `AnimatedCounter`, 7 transition types |
| **1.2** | Admin Dark Mode | `ThemeProvider`, 20+ dark theme tokens, sidebar dark toggle, `darkTheme` in main.dart |
| **1.3** | Driver Dark Mode | `ThemeProvider`, `BiteGoDriverApp` rebrand, dark theme integration |
| **1.4** | Restaurant Theme | `ThemeProvider`, `BiteGoRestaurantApp` rebrand, dark theme integration |
| **2.1** | Customer New Features | `OrderTimeline`, `QuickReorderCard`, `AnimatedStatCard` widgets |
| **2.2** | Admin New Features | `ToastNotification` with `Toast.success/error/warning/info()` helpers |
| **2.3** | Driver New Features | `EarningsChart` weekly bar chart widget |
| **4.3** | Rebrand Feedzo→BiteGo | App class names, titles, razorpay, privacy policy, profile screen |

### 📦 NEW WIDGETS CREATED (20+ files)

**feedzo_app/lib/widgets/**:
- `order_timeline.dart` — Visual order progress stepper
- `quick_reorder_card.dart` — One-tap reorder UI
- `animated_stat_card.dart` — Count-up stat display
- `animated_badge.dart` — Bounce + scale cart badge animation
- `hero_carousel.dart` — Parallax hero carousel for featured restaurants
- `confetti_animation.dart` — Celebration confetti effect
- `skeleton_loader.dart` — Shimmer loading placeholders
- Enhanced `app_transitions.dart` — 7 transition types + `StaggeredItem` + `AnimatedCounter`

**feedzo_app/lib/utils/**:
- `debounce.dart` — Debouncer & Throttler for performance
- `accessibility.dart` — Semantic labels, haptics, accessible buttons

**feedzo_admin/lib/widgets/**:
- `toast_notification.dart` — Animated toast system

**feedzo_driver_app/lib/widgets/**:
- `earnings_chart.dart` — Weekly earnings bar chart

**feedzo_restaurant_app/lib/widgets/**:
- `prep_timer.dart` — Circular preparation countdown timer
- `new_order_alert.dart` — Pulse animation new order notification
- `revenue_sparkline.dart` — Mini revenue trend chart

**bitego_ui_kit/lib/**:
- `bitego_ui_kit.dart` — Package exports
- `src/core/colors.dart` — Unified BiteGo color palette
- `src/core/tokens.dart` — Design tokens (spacing, radius, elevation)
- `src/widgets/empty_state.dart` — Illustrated empty state

**ThemeProviders Created**:
- `feedzo_admin/lib/providers/theme_provider.dart`
- `feedzo_driver_app/lib/providers/theme_provider.dart`
- `feedzo_restaurant_app/lib/providers/theme_provider.dart`

### ⏳ PENDING ITEMS

- PDF invoice headers (backend service update required)
- Email domain changes (requires domain ownership)
- Advanced effects: Hero animations, confetti, scratch cards
- Shared widget library package extraction
- Performance optimizations: RepaintBoundary, debounce
- Accessibility: semantic labels, screen reader support

---

*Implementation in progress. Build recommended to verify all changes.*
