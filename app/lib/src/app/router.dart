import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/groups/presentation/group_form_screen.dart';
import '../features/groups/presentation/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'group/create',
          builder: (context, state) => const GroupFormScreen(),
        ),
        GoRoute(
          path: 'group/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PlaceholderScreen(title: 'Group Overview: $id');
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return GroupFormScreen(groupId: id);
              },
            ),
            GoRoute(
              path: 'members',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Members'),
            ),
            GoRoute(
              path: 'balances',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Balances'),
            ),
            GoRoute(
              path: 'settlements',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Settlements'),
            ),
            GoRoute(
              path: 'tags',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Tags'),
            ),
            GoRoute(
              path: 'transactions',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Transactions'),
              routes: [
                GoRoute(
                  path: 'add-expense',
                  builder: (context, state) =>
                      const PlaceholderScreen(title: 'Add Expense'),
                ),
                GoRoute(
                  path: 'add-transfer',
                  builder: (context, state) =>
                      const PlaceholderScreen(title: 'Add Transfer'),
                ),
                GoRoute(
                  path: ':txId',
                  builder: (context, state) {
                    final txId = state.pathParameters['txId']!;
                    return PlaceholderScreen(
                      title: 'Transaction Detail: $txId',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
    ),
  ],
);

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
