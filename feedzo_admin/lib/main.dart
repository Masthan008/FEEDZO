import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/responsive.dart';
import 'providers/admin_provider.dart';
import 'providers/theme_provider.dart';
import 'shell.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // OneSignal init for admin web - skip on web to prevent unsupported errors
  if (!kIsWeb) {
    OneSignal.initialize('90f7c5c6-b51f-466a-acdb-a4829b419363');
  }
  runApp(const BiteGoAdminApp());
}

class BiteGoAdminApp extends StatelessWidget {
  const BiteGoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => ResponsiveBuilder(
          builder: (context, info) => MaterialApp(
            title: 'BiteGo Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const _AuthGate(),
            builder: (context, child) {
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

/// Listens to Firebase Auth state — no manual flag needed.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase to respond
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          // Register admin in OneSignal with admin role tag (skip on web)
          if (!kIsWeb) {
            OneSignal.login(snapshot.data!.uid);
            OneSignal.User.addTagWithKey('role', 'admin');
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminProvider>().loginWithFirebase(
              snapshot.data!.uid,
              snapshot.data!.email ?? '',
            );
          });
          return const AdminShell();
        }
        // Not signed in
        return const LoginScreen();
      },
    );
  }
}
