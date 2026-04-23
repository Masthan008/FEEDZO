import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/responsive.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/hike_charges_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/waiting_approval_screen.dart';
import 'screens/home/home_shell.dart';

import 'services/onesignal_service.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/hike_charges_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize OneSignal with navigation callback
  await OneSignalService.init(
    onNavigate: (type, data) {
      _handleNotificationNavigation(type, data);
    },
  );

  runApp(const BiteGoRestaurantApp());
}

/// Handle navigation when user taps notification
void _handleNotificationNavigation(String type, Map<String, dynamic>? data) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  switch (type) {
    case 'new_order':
      final orderId = data?['orderId'] as String?;
      if (orderId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      }
      break;
    case 'order_status':
      final orderId = data?['orderId'] as String?;
      if (orderId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      }
      break;
    case 'payment':
      // Navigate to wallet screen
      navigatorKey.currentState?.pushNamed('/wallet');
      break;
    default:
      // Default to orders screen
      navigatorKey.currentState?.pushNamed('/orders');
  }
}

class BiteGoRestaurantApp extends StatelessWidget {
  const BiteGoRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => HikeChargesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => ResponsiveBuilder(
          builder: (context, info) => MaterialApp(
            navigatorKey: navigatorKey,
            title: 'BiteGo Restaurant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const _AuthGate(),
          routes: {
            '/hike-charges': (context) => const HikeChargesScreen(),
          },
          builder: (context, child) {
            // Ensure text scaling doesn't break layout
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(info.textScale.clamp(0.8, 1.2)),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasData && snap.data != null) {
          final user = snap.data!;
          OneSignalService.loginUser(user.uid);
          OneSignalService.setRole('restaurant');
          OneSignalService.setRestaurantId(user.uid);

          if (!auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              auth.syncFromFirebase(user);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!auth.isApproved) {
            return const WaitingApprovalScreen();
          }

          return const HomeShell();
        }

        return const LoginScreen();
      },
    );
  }
}
