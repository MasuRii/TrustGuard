import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/export_backup/presentation/export_screen.dart';
import '../features/balances/presentation/balances_screen.dart';
import '../features/balances/presentation/settlements_screen.dart';
import '../features/groups/presentation/group_form_screen.dart';
import '../features/groups/presentation/group_overview_screen.dart';
import '../features/groups/presentation/home_screen.dart';
import '../features/groups/presentation/members_screen.dart';
import '../features/transactions/presentation/add_expense_screen.dart';
import '../features/transactions/presentation/add_transfer_screen.dart';
import '../features/transactions/presentation/tags_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';
import '../features/reminders/presentation/reminder_settings_screen.dart';
import '../features/settings/presentation/lock_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/pin_setup_screen.dart';
import '../features/settings/providers/lock_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final lockState = ref.watch(appLockStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (!lockState.isInitialized) return null;

      final isLocked = lockState.isLocked;
      final goingToLock = state.matchedLocation == '/lock';

      if (isLocked && !goingToLock) {
        return '/lock';
      }
      if (!isLocked && goingToLock) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
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
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TagsScreen(groupId: id);
                },
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ReminderSettingsScreen(groupId: id);
                },
              ),
              GoRoute(
                path: 'export',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ExportScreen(groupId: id);
                },
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
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'pin-setup',
            builder: (context, state) => const PinSetupScreen(),
          ),
        ],
      ),
    ],
  );
});

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
