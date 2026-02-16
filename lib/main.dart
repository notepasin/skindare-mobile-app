import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skindare/core/constants/route_names.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/routine/screens/home_screen.dart';

void main() {
  runApp(const SkindareApp());
}

class SkindareApp extends StatelessWidget {
  const SkindareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Skindare',
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
