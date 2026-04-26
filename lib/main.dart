import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/models/maintenance_status.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/student_dashboard_page.dart';
import 'features/public/presentation/pages/landing_page.dart';
import 'features/shared/presentation/controllers/maintenance_controller.dart';
import 'features/shared/presentation/pages/maintenance_page.dart';

Widget _resolveUnauthenticatedPage() {
  final screen = Uri.base.queryParameters['screen']?.toLowerCase().trim();
  switch (screen) {
    case 'login':
      return const LoginPage();
    case 'register':
      return const RegisterPage();
    case 'forgot-password':
      return const ForgotPasswordPage();
    case 'reset-password':
      return ResetPasswordPage(token: Uri.base.queryParameters['token']);
    case 'landing':
      return const LandingPage();
    default:
      return const LoginPage();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => MaintenanceController()),
      ],
      child: const MyVoiceBridgeApp(),
    ),
  );
}

class MyVoiceBridgeApp extends StatelessWidget {
  const MyVoiceBridgeApp({super.key});

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final tab = StudentDashboardPage.tabFromRouteName(settings.name);
    final studentRoutes = <String>{
      StudentDashboardPage.routeHome,
      StudentDashboardPage.routeHelpdesk,
      StudentDashboardPage.routeSubmit,
      StudentDashboardPage.routeMyComplaints,
      StudentDashboardPage.routeAppointments,
      StudentDashboardPage.routeFeedback,
      StudentDashboardPage.routeNotifications,
      StudentDashboardPage.routeAnnouncements,
      StudentDashboardPage.routeProfile,
    };

    if (studentRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => StudentDashboardPage(initialTab: tab),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceBridge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      onGenerateRoute: _onGenerateRoute,
      home: const AppBootstrapGate(),
    );
  }
}

class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({super.key});

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    unawaited(
      context.read<AuthController>().bootstrap().catchError((_) {
        // Continue startup even when network-bound bootstrap calls fail.
      }),
    );

    unawaited(
      context.read<MaintenanceController>().loadStatus().catchError((_) {
        // Maintenance checks should not block unauthenticated screens.
      }),
    );

    if (!mounted) return;
    setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const _SplashScreen();
    }

    final auth = context.watch<AuthController>();
    final maintenance = context.watch<MaintenanceController>();
    final maintenanceStatus = MaintenanceStatus(
      isEnabled: maintenance.isMaintenanceMode,
      message: maintenance.message,
    );

    if (maintenanceStatus.isEnabled) {
      return MaintenancePage(message: maintenanceStatus.message);
    }

    if (auth.user == null) {
      return _resolveUnauthenticatedPage();
    }

    return const HomePage();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading ...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
