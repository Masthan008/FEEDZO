import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/responsive.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/auth_gateway_screen.dart';
import 'screens/main_shell.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/orders/order_tracking_screen.dart';

import 'package:flutter/foundation.dart';
import 'services/onesignal_service.dart';
import 'services/offline_service.dart';

/// Global navigator key — used by OneSignal for deep-link navigation.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await OneSignalService.init();
    await OfflineService.initialize();
  }
  runApp(const BiteGoApp());
}

class BiteGoApp extends StatelessWidget {
  const BiteGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => ResponsiveBuilder(
          builder: (context, info) => MaterialApp(
            title: 'BiteGo',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            routes: {
              '/cart': (_) => const CartScreen(),
              '/dashboard': (_) => const DashboardScreen(),
            },
            onGenerateRoute: (settings) {
              // Deep link route for order tracking
              if (settings.name?.startsWith('/order/') ?? false) {
                final orderId = settings.name!.replaceFirst('/order/', '');
                return MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: orderId),
                );
              }
              return null;
            },
            home: const _AuthGate(),
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
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', width: 80),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          );
        }
        if (snap.hasData && snap.data != null) {
          if (!kIsWeb) {
            OneSignalService.loginUser(snap.data!.uid);
            OneSignalService.setRole('customer');
          }
          return const MainShell();
        }
        return const AuthGatewayScreen();
      },
    );
  }
}
