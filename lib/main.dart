import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>(
      create: (_) => AppController(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
        storage: FirebaseStorage.instance,
      ),
      child: Consumer<AppController>(
        builder: (context, controller, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Digital Committee Management',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
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
    if (controller.loading && controller.firebaseUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
