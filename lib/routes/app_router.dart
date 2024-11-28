import 'package:frontend/groupInfo/Add/AddEventPage.dart';
import 'package:frontend/groupInfo/Add/AddPollPage.dart';
import 'package:frontend/groupInfo/Add/AddPostPage.dart';
import 'package:frontend/groupInfo/SubgroupsPage.dart';
import 'package:frontend/inital/Details/eventsDetailsPage.dart';
import 'package:frontend/inital/aboutpage.dart';
import 'package:frontend/inital/main_layout.dart';
import 'package:frontend/groupInfo/GroupDetailsPage.dart';
import 'package:frontend/groupInfo/MembershipPage.dart';
import 'package:frontend/inital/groupspage.dart';
import 'package:frontend/inital/homepage.dart';
import 'package:frontend/inital/messagespage.dart';
import 'package:go_router/go_router.dart';
import '../onboarding/options_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home', // Set /home as the initial location
    routes: [
      GoRoute(
        name: 'options',
        path: '/options',
        builder: (context, state) => const OptionsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            name: 'about',
            path: '/about',
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: '/event-details/:eventId',
            name: 'eventDetails',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return EventDetailsPage(eventId: eventId);
            },
          ),
          GoRoute(
            path: '/home/groups',
            name: 'groups',
            pageBuilder: (context, state) => const NoTransitionPage(
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
                    path: 'subgroups',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return SubgroupsPage(groupId: groupId);
                    },
                  ),
                  GoRoute(
                    path: 'add-post/:subgroupId',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final subgroupId = state.pathParameters['subgroupId']!;
                      return AddPostPage(
                          groupId: groupId, subgroupId: subgroupId);
                    },
                  ),
                  GoRoute(
                    path: 'add-poll/:subgroupId',
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
