// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:frontend/inital/main_layout.dart';
import 'package:frontend/inital/GroupDetailsPage.dart';
import 'package:frontend/inital/groupspage.dart';
import 'package:frontend/inital/homepage.dart';
import 'package:frontend/inital/messagespage.dart';
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
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/home/groups',
            name: 'groups',
            pageBuilder: (context, state) => NoTransitionPage(
              child: GroupsPage(),
            ),
            routes: [
              GoRoute(
                path: 'group-details/:groupId',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return NoTransitionPage(
                    child: GroupDetailsPage(groupId: groupId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/home/messages',
            name: 'messages',
            pageBuilder: (context, state) => NoTransitionPage(
              child: MessagesPage(),
            ),
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
      context.goNamed('groups'); // Navigate to Groups page if authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAuthStatus(context);
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
