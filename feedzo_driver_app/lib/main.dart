import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/responsive.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/approval_gate.dart';

import 'services/onesignal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OneSignalService.init();
  runApp(const BiteGoDriverApp());
}

class BiteGoDriverApp extends StatelessWidget {
  const BiteGoDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ResponsiveBuilder(
        builder: (context, info) => Consumer<ThemeProvider>(
          builder: (_, theme, __) => MaterialApp(
            title: 'BiteGo Driver',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData && snap.data != null) {
          OneSignalService.loginUser(snap.data!.uid);
          OneSignalService.setRole('driver');
          return ApprovalGate(child: const MainShell());
        }
        return const LoginScreen();
      },
    );
  }
}
