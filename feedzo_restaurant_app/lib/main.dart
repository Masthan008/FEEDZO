import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'firebase_options.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/hike_charges_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/waiting_approval_screen.dart';
import 'screens/home/home_shell.dart';

import 'services/onesignal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OneSignalService.init();
  runApp(const FeedzoRestaurantApp());
}

class FeedzoRestaurantApp extends StatelessWidget {
  const FeedzoRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => HikeChargesProvider()),
      ],
      child: MaterialApp(
        title: 'Feedzo Restaurant',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const _AuthGate(),
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
