import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/widgets/app_navigation_scaffold.dart';
import 'package:skindare/core/constants/route_names.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/routine/screens/add_product_screen.dart';
import 'features/skincare/screens/edit_product_screen.dart';
import 'features/profile/screens/skin_profile_screen.dart';
import 'features/routine/screens/routine_builder_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/routine/screens/history_screen.dart';
import 'features/auth/screens/forget_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkindareApp());
}

class SkindareApp extends StatelessWidget {
  const SkindareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Skindare',

      /// 🔥 THEME FIX (ไม่มีสีม่วงอีกต่อไป)
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFFEAF3FB),
        colorScheme: const ColorScheme.light(primary: Color(0xFF4A90E2)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  /// 🔥 ไม่ต้อง initialLocation แล้ว
  initialLocation: '/login',

  /// 🔥 AUTH GUARD
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final loggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forget-password';

    if (user == null && !loggingIn) {
      return '/login';
    }

    if (user != null && loggingIn) {
      return '/home';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

    GoRoute(
      path: '/forget-password',
      builder: (context, state) => const ForgetPasswordScreen(),
    ),

    GoRoute(
      path: '/home',
      builder: (context, state) => const AppNavigationScaffold(),
    ),

    GoRoute(
      path: '/add-product',
      builder: (context, state) => const AddProductScreen(),
    ),

    GoRoute(
      path: '/edit-product',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return EditProductScreen(
          docId: data['docId'],
          name: data['name'],
          type: data['type'],
        );
      },
    ),

    GoRoute(
      path: '/skin-profile',
      builder: (context, state) => const SkinProfileScreen(),
    ),

    GoRoute(
      path: '/routine-builder',
      builder: (context, state) => const RoutineBuilderScreen(),
    ),

    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),

    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
);
