import 'package:flutter/material.dart';
import 'package:frontend/inital/GroupDetailsPage.dart';
import 'package:frontend/inital/main_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/options_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/check-auth',
    routes: [
      GoRoute(
        path: '/check-auth',
        builder: (context, state) => AuthCheckScreen(),
      ),
      GoRoute(
        path: '/options',
        builder: (context, state) => OptionsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => MainLayout(),
        routes: [
          // Nested route for Group Details page
          GoRoute(
            path: 'group-details/:groupId',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return GroupDetailsPage(groupId: groupId);
            },
          ),
        ],
      ),
    ],
  );
}

class AuthCheckScreen extends StatelessWidget {
  Future<void> _checkAuthStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      context.go('/options'); // Navigate to options screen if not authenticated
    } else {
      context.go('/home'); // Navigate to homepage if authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAuthStatus(context);
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
