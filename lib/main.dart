import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_routes.dart';
import 'controllers/app_controller.dart';
import 'screens/admin_verification_panel_screen.dart';
import 'screens/create_committee_screen.dart';
import 'screens/dispute_screen.dart';
import 'screens/group_dashboard_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/join_committee_screen.dart';
import 'screens/login_screen.dart';
import 'screens/messaging_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/trust_profile_screen.dart';
import 'screens/verification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EzCommitteeApp());
}

class EzCommitteeApp extends StatelessWidget {
  const EzCommitteeApp({super.key});

  static const _brandGradient = LinearGradient(
    colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>(
      create: (_) => AppController(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
      child: Consumer<AppController>(
        builder: (context, controller, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Digital Committee Management',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                primary: const Color(0xFF3949AB),
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F7FC),
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
              cardTheme: CardThemeData(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.indigo.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF3949AB)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(fontWeight: FontWeight.w700),
                titleLarge: TextStyle(fontWeight: FontWeight.w700),
                titleMedium: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            home: _RootGate(controller: controller),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.login:
                  return MaterialPageRoute<void>(
                    builder: (_) => const LoginScreen(),
                  );
                case AppRoutes.verification:
                  return MaterialPageRoute<void>(
                    builder: (_) => const VerificationScreen(),
                  );
                case AppRoutes.home:
                  return MaterialPageRoute<void>(
                    builder: (_) => const HomeDashboardScreen(),
                  );
                case AppRoutes.createCommittee:
                  return MaterialPageRoute<void>(
                    builder: (_) => const CreateCommitteeScreen(),
                  );
                case AppRoutes.joinCommittee:
                  return MaterialPageRoute<void>(
                    builder: (_) => const JoinCommitteeScreen(),
                  );
                case AppRoutes.trustProfile:
                  return MaterialPageRoute<void>(
                    builder: (_) => const TrustProfileScreen(),
                  );
                case AppRoutes.adminPanel:
                  return MaterialPageRoute<void>(
                    builder: (_) => const AdminVerificationPanelScreen(),
                  );
                case AppRoutes.groupDashboard:
                  final committeeId = settings.arguments as String? ?? '';
                  return MaterialPageRoute<void>(
                    builder: (_) =>
                        GroupDashboardScreen(committeeId: committeeId),
                  );
                case AppRoutes.payment:
                  final args = settings.arguments as PaymentScreenArgs;
                  return MaterialPageRoute<void>(
                    builder: (_) => PaymentScreen(
                      committee: args.committee,
                      paymentRecord: args.payment,
                    ),
                  );
                case AppRoutes.messaging:
                  final args = settings.arguments as MessagingScreenArgs;
                  return MaterialPageRoute<void>(
                    builder: (_) => MessagingScreen(
                      committeeId: args.committeeId,
                      committeeName: args.committeeName,
                    ),
                  );
                case AppRoutes.dispute:
                  final args = settings.arguments as DisputeScreenArgs;
                  return MaterialPageRoute<void>(
                    builder: (_) => DisputeScreen(
                      committeeId: args.committeeId,
                      committeeName: args.committeeName,
                    ),
                  );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final overlay = Container(
      decoration: const BoxDecoration(gradient: EzCommitteeApp._brandGradient),
    );
    if (controller.loading && controller.firebaseUser == null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            overlay,
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ],
        ),
      );
    }
    if (!controller.isSignedIn) {
      return const LoginScreen();
    }
    if (controller.needsVerification) {
      return const VerificationScreen();
    }
    return const HomeDashboardScreen();
  }
}
