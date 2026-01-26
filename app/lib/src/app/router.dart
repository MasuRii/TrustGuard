import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/balances/presentation/balances_screen.dart';
import '../features/balances/presentation/settlements_screen.dart';
import '../features/groups/presentation/group_form_screen.dart';
import '../features/groups/presentation/group_overview_screen.dart';
import '../features/groups/presentation/home_screen.dart';
import '../features/groups/presentation/members_screen.dart';
import '../features/transactions/presentation/add_expense_screen.dart';
import '../features/transactions/presentation/add_transfer_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';

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
            return GroupOverviewScreen(groupId: id);
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
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return MembersScreen(groupId: id);
              },
            ),
            GoRoute(
              path: 'balances',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return BalancesScreen(groupId: id);
              },
            ),
            GoRoute(
              path: 'settlements',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return SettlementsScreen(groupId: id);
              },
            ),
            GoRoute(
              path: 'tags',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Tags'),
            ),
            GoRoute(
              path: 'transactions',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return TransactionListScreen(groupId: id);
              },
              routes: [
                GoRoute(
                  path: 'add-expense',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final txId = state.uri.queryParameters['txId'];
                    return AddExpenseScreen(groupId: id, transactionId: txId);
                  },
                ),
                GoRoute(
                  path: 'add-transfer',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final txId = state.uri.queryParameters['txId'];
                    final fromId = state.uri.queryParameters['fromId'];
                    final toId = state.uri.queryParameters['toId'];
                    final amount = state.uri.queryParameters['amount'];
                    final note = state.uri.queryParameters['note'];
                    return AddTransferScreen(
                      groupId: id,
                      transactionId: txId,
                      initialFromId: fromId,
                      initialToId: toId,
                      initialAmount: amount,
                      initialNote: note,
                    );
                  },
                ),
                GoRoute(
                  path: ':txId',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final txId = state.pathParameters['txId']!;
                    return TransactionDetailScreen(
                      groupId: id,
                      transactionId: txId,
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
