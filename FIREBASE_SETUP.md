# Feedzo Firebase Setup Guide

## 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project" → name it `feedzo-app`
3. Enable Google Analytics (optional)

---

## 2. Enable Firebase Services

### Authentication
- Console → Authentication → Get Started
- Enable **Email/Password** provider

### Firestore Database
- Console → Firestore Database → Create database
- Start in **production mode** (rules are in `firestore.rules`)
- Choose region closest to your users

### Cloud Messaging (FCM)
- Enabled by default — no extra setup needed for basic push

---

## 3. Register Apps

### Android (shared google-services.json)
Each Flutter app needs its own Android app registered:

| App | Package Name |
|-----|-------------|
| Customer | `com.feedzo.app` |
| Restaurant | `com.feedzo.restaurant` |
| Driver | `com.feedzo.driver` |
| Admin (web) | N/A |

For each:
1. Console → Project Settings → Add app → Android
2. Enter package name
3. Download `google-services.json`
4. Place in `<app>/android/app/google-services.json`

### iOS
1. Console → Add app → iOS
2. Enter bundle ID (e.g. `com.feedzo.app`)
3. Download `GoogleService-Info.plist`
4. Place in `<app>/ios/Runner/GoogleService-Info.plist`

### Web (Admin Panel)
1. Console → Add app → Web
2. Copy the config object
3. Paste values into `feedzo_admin/lib/firebase_options.dart`

---

## 4. Run FlutterFire CLI (Recommended)

This auto-generates `firebase_options.dart` for each app:

```bash
# Install once
dart pub global activate flutterfire_cli

# Run in each app folder
cd feedzo_admin
flutterfire configure --project=feedzo-app

cd ../feedzo_app
flutterfire configure --project=feedzo-app

cd ../feedzo_driver_app
flutterfire configure --project=feedzo-app

cd ../feedzo_restaurant_app
flutterfire configure --project=feedzo-app
```

---

## 5. Android Setup

In each app's `android/build.gradle` (project level):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
}
```

In `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 6. Deploy Firestore Rules

```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login
firebase init firestore   # select feedzo-app project
firebase deploy --only firestore:rules
```

---

## 7. Firestore Collections Structure

```
users/
  {uid}/
    id, name, email, role, fcmToken, createdAt

restaurants/
  {uid}/
    id, name, commission_percent, wallet_balance, status

drivers/
  {uid}/
    id, name, phone, vehicle, status, totalDeliveries, rating

orders/
  {orderId}/
    customerId, restaurantId, driverId, driverName
    status: placed | preparing | out_for_delivery | delivered | cancelled
    totalAmount, paymentType: cod | online
    items: [{name, qty, price}]
    createdAt, updatedAt

settlements/
  {driverId}/
    driverId, codCollected, submitted, pending, updatedAt

transactions/
  {txId}/
    restaurantId, orderId, amount, type: commission | payout, createdAt

notifications/
  {notifId}/
    targetUserId, title, body, data, sent, createdAt
```

---

## 8. FCM Push Notifications

Notifications are triggered by writing to the `notifications` collection.
Deploy a **Cloud Function** to send the actual FCM message:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap) => {
    const { targetUserId, title, body, data } = snap.data();
    const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return;
    await admin.messaging().send({ token, notification: { title, body }, data });
    await snap.ref.update({ sent: true });
  });
```

Deploy: `firebase deploy --only functions`

---

## 9. Install Dependencies

Run in each app folder:
```bash
flutter pub get
```
