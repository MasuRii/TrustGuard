import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/export_backup/presentation/export_screen.dart';
import '../features/export_backup/presentation/backup_screen.dart';
import '../features/balances/presentation/balances_screen.dart';
import '../features/balances/presentation/settlements_screen.dart';
import '../features/groups/presentation/group_form_screen.dart';
import '../features/groups/presentation/group_overview_screen.dart';
import '../features/groups/presentation/home_screen.dart';
import '../features/groups/presentation/members_screen.dart';
import '../features/sharing/presentation/scan_expense_screen.dart';
import '../features/budget/presentation/budget_settings_screen.dart';
import '../core/models/budget.dart';
import '../core/models/expense_template.dart';
import '../features/transactions/presentation/add_expense_screen.dart';

import '../features/transactions/presentation/add_transfer_screen.dart';
import '../features/transactions/presentation/tags_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/reminders/presentation/reminder_settings_screen.dart';
import '../features/settings/presentation/lock_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/pin_setup_screen.dart';
import '../features/settings/presentation/debug_logs_screen.dart';
import '../features/settings/presentation/help_screen.dart';
import '../features/settings/providers/lock_providers.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../ui/animations/page_transitions.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final lockState = ref.watch(appLockStateProvider);
  final onboardingState = ref.watch(onboardingStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 1. Check onboarding first
      final isOnboardingComplete = onboardingState.isComplete;
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isOnboardingComplete) {
        return goingToOnboarding ? null : '/onboarding';
      }

      // 2. If onboarding complete but still going to onboarding, redirect home
      if (goingToOnboarding) {
        return '/';
      }

      // 3. Handle lock state
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ).withTransition(TransitionType.fadeThrough),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ).withTransition(TransitionType.fadeThrough),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'group/create',
            builder: (context, state) => const GroupFormScreen(),
          ).withTransition(TransitionType.sharedAxisHorizontal),
          GoRoute(
            path: 'group/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final tab = state.uri.queryParameters['tab'];
              final initialTabIndex = tab == 'budgets' ? 1 : 0;
              return GroupOverviewScreen(
                groupId: id,
                initialTabIndex: initialTabIndex,
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return GroupFormScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'members',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MembersScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'balances',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BalancesScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'settlements',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SettlementsScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'tags',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TagsScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'analytics',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AnalyticsScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'reminders',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ReminderSettingsScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'budget-settings',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final budget = state.extra as Budget?;
                  return BudgetSettingsScreen(groupId: id, budget: budget);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),

              GoRoute(
                path: 'export',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ExportScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'import',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ImportScreen(groupId: id);
                },
              ).withTransition(TransitionType.sharedAxisHorizontal),
              GoRoute(
                path: 'scan',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ScanExpenseScreen(groupId: id);
                },
              ).withTransition(TransitionType.fadeThrough),
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
                      final scan = state.uri.queryParameters['scan'] == 'true';
                      final template = state.extra as ExpenseTemplate?;
                      return AddExpenseScreen(
                        groupId: id,
                        transactionId: txId,
                        initialScan: scan,
                        initialTemplate: template,
                      );
                    },
                  ).withTransition(TransitionType.sharedAxisHorizontal),
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
                  ).withTransition(TransitionType.sharedAxisHorizontal),
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
                  ).withTransition(TransitionType.sharedAxisHorizontal),
                ],
              ).withTransition(TransitionType.sharedAxisHorizontal),
            ],
          ).withTransition(TransitionType.sharedAxisHorizontal),
        ],
      ).withTransition(TransitionType.fadeThrough),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'pin-setup',
            builder: (context, state) => const PinSetupScreen(),
          ).withTransition(TransitionType.sharedAxisHorizontal),
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupScreen(),
          ).withTransition(TransitionType.sharedAxisHorizontal),
          GoRoute(
            path: 'debug-logs',
            builder: (context, state) => const DebugLogsScreen(),
          ).withTransition(TransitionType.sharedAxisHorizontal),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpScreen(),
          ).withTransition(TransitionType.sharedAxisHorizontal),
        ],
      ).withTransition(TransitionType.fadeThrough),
    ],
  );
});

extension GoRouteTransition on GoRoute {
  GoRoute withTransition(TransitionType type) {
    return GoRoute(
      path: path,
      name: name,
      pageBuilder: (context, state) => AppPageTransitions.buildPage(
        context: context,
        key: state.pageKey,
        type: type,
        child: builder!(context, state),
      ),
      routes: routes,
      redirect: redirect,
      parentNavigatorKey: parentNavigatorKey,
    );
  }
}

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
