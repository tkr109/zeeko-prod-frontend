// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:frontend/groupInfo/Add/AddEventPage.dart';
import 'package:frontend/groupInfo/Add/AddPollPage.dart';
import 'package:frontend/groupInfo/Add/AddPostPage.dart';
import 'package:frontend/groupInfo/SubgroupsPage.dart';
import 'package:frontend/inital/main_layout.dart';
import 'package:frontend/groupInfo/GroupDetailsPage.dart';
import 'package:frontend/groupInfo/MembershipPage.dart';
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
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return GroupDetailsPage(groupId: groupId);
                },
                routes: [
                  GoRoute(
                    path: 'membership',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return MembershipPage(groupId: groupId);
                    },
                  ),
                  GoRoute(
                    path: 'subgroups', // Define route for SubgroupsPage
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return SubgroupsPage(
                          groupId: groupId); // Pass groupId to SubgroupsPage
                    },
                  ),
                  GoRoute(
                    path: 'add-post/:subgroupId', // Route for AddPostPage
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final subgroupId = state.pathParameters['subgroupId']!;
                      return AddPostPage(
                          groupId: groupId, subgroupId: subgroupId);
                    },
                  ),
                  GoRoute(
                    path: 'add-poll/:subgroupId', // Route for AddPollPage
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final subgroupId = state.pathParameters['subgroupId']!;
                      return AddPollPage(
                          groupId: groupId, subgroupId: subgroupId);
                    },
                  ),
                  GoRoute(
                    path: 'add-event/:subgroupId',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final subgroupId = state.pathParameters['subgroupId']!;
                      return AddEventPage(
                          groupId: groupId, subgroupId: subgroupId);
                    },
                  ),
                ],
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
