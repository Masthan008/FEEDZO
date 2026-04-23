# BiteGo Ecosystem — UI/UX, Transitions, Features & Effects Plan

> **Status**: IN PROGRESS — Implementation underway  
> **Last Updated**: 2025-04-23 — Phase 1, 2.1, 2.2, 4.3 COMPLETED  
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

### 1.4 Restaurant App — Theme & Transitions
- [ ] Create full `AppTheme` class with light + dark themes
- [ ] Add `ThemeProvider` with dark mode toggle
- [ ] Add page transitions for all navigation
- [ ] Add animated order cards with status color transitions
- [ ] Add shimmer loading for dashboard stats and order lists
- [ ] Add new order notification with sound + visual pulse animation
- [ ] Add drag-to-reorder for menu items
- [ ] Add animated chart transitions on reports screen

---

## Phase 2 — New Features & Screen Enhancements

### 2.1 Customer App — New Features
- [ ] **Live Order Tracking Map**: Real-time driver location with animated route polyline, ETA countdown, driver info card
- [ ] **Smart Cart Suggestions**: AI-powered add-on suggestions in cart ("Frequently ordered together")
- [ ] **Order Timeline**: Visual stepper/timeline for order status (Placed → Confirmed → Preparing → Picked Up → Delivered)
- [ ] **Restaurant Story Mode**: Vertical swipeable stories for restaurant promotions (like Instagram)
- [ ] **Quick Reorder**: One-tap reorder from order history with animated confirmation
- [ ] **Split Bill Feature**: Enhanced split payment with animated bill-splitting UI
- [ ] **Voice Search**: Re-enable with compatible plugin + animated waveform visualization
- [ ] **Gesture Navigation**: Swipe from edge to go back with parallax effect
- [ ] **Favorites Animation**: Heart burst animation when adding to favorites
- [ ] **Wallet Top-up Flow**: Animated coin/money transition during wallet top-up
- [ ] **Rating Experience**: Star rating with particle effects, optional emoji reactions
- [ ] **Coupon Scratch Card**: Scratch-to-reveal coupon animation on promotions

### 2.2 Admin App — New Features
- [ ] **Real-time Dashboard Charts**: Animated line/bar charts with live data streaming
- [ ] **Map View**: Fleet map showing all driver locations in real-time
- [ ] **Drag & Drop Kanban**: Order management with drag-to-change-status columns
- [ ] **Notification Center**: Bell icon with animated badge count, notification list
- [ ] **Quick Actions Bar**: Floating action bar for common admin tasks
- [ ] **Data Export Animations**: Progress animation during CSV/PDF exports
- [ ] **Bulk Operations**: Multi-select with animated checkboxes for bulk actions
- [ ] **Search & Command Palette**: Ctrl+K style search for quick navigation
- [ ] **Toast Notifications**: Animated slide-in toasts instead of static snackbars
- [ ] **Screen Recording**: Audit trail with visual replay of admin actions

### 2.3 Driver App — New Features
- [ ] **Heat Map**: Show high-demand areas on map with pulsing zones
- [ ] **Earnings Chart**: Weekly/monthly earnings chart with animated transitions
- [ ] **Achievement Badges**: Gamification with unlock animations (100 deliveries, 5-star streak, etc.)
- [ ] **Navigation Integration**: In-app turn-by-turn navigation with voice
- [ ] **Quick Stats Widget**: Home screen widget showing today's earnings
- [ ] **Multi-Stop Routing**: Visual route with multiple delivery stops
- [ ] **Emergency Button**: SOS with animated pulse and quick-call feature
- [ ] **Chat with Customer/Restaurant**: In-app chat with typing indicators

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

### 4.1 Shared Widget Library (bitego_ui_kit)
- [ ] Create shared package with common widgets:
  - `BiteGoStatCard` — Animated stat card with icon, value, trend
  - `BiteGoEmptyState` — Illustrated empty state with action button
  - `BiteGoSkeleton` — Shimmer loading placeholder
  - `BiteGoStatusBadge` — Color-coded status indicator
  - `BiteGoAnimatedButton` — Press-scale feedback button
  - `BiteGoSearchBar` — Animated search input with voice icon
  - `BiteGoAvatar` — Profile avatar with online indicator
  - `BiteGoBadge` — Notification badge with bounce animation
  - `BiteGoBottomSheet` — Draggable bottom sheet with morphing handle
  - `BiteGoTransitions` — Page route transitions collection

### 4.2 Design Token Unification
- [ ] Align color palette across all 4 apps (same primary, accent, semantic colors)
- [ ] Unify border radius tokens (small=8, medium=12, large=16, xl=24, round=full)
- [ ] Unify spacing tokens (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32)
- [ ] Unify elevation/shadow system
- [ ] Unify typography scale (using Google Fonts Inter consistently)

### 4.3 Rebrand Completion
- [ ] Replace all remaining "Feedzo" references with "BiteGo" across all 4 apps
- [ ] Update all PDF invoice headers from "FEEDZO" to "BITEGO"
- [ ] Update all "About Feedzo" dialogs to "About BiteGo"
- [ ] Update all onboarding text references
- [ ] Update Firebase project display name if needed

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

*Awaiting review and approval before implementation begins.*
