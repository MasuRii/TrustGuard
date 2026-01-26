import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/money.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import '../services/balance_service.dart';

class BalancesScreen extends ConsumerWidget {
  final String groupId;

  const BalancesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: groupAsync.when(
        data: (group) {
          final currency = group?.currencyCode ?? 'USD';
          return balancesAsync.when(
            data: (balances) {
              if (balances.isEmpty) {
                return const Center(child: Text('No members in this group'));
              }

              // Sort balances: creditors first, then settled, then debtors
              final sortedBalances = List.of(balances)
                ..sort((a, b) => b.netAmountMinor.compareTo(a.netAmountMinor));

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.space16),
                itemCount: sortedBalances.length,
                itemBuilder: (context, index) {
                  final balance = sortedBalances[index];
                  final isSettled = balance.netAmountMinor == 0;
                  final isCreditor = balance.netAmountMinor > 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.space8),
                    child: ListTile(
                      title: Text(
                        balance.memberName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isSettled
                            ? 'Settled'
                            : isCreditor
                            ? 'is owed'
                            : 'owes',
                      ),
                      trailing: Text(
                        MoneyUtils.format(
                          balance.netAmountMinor.abs(),
                          currencyCode: currency,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSettled
                              ? null
                              : isCreditor
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading balances: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading group: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/$groupId/settlements'),
        label: const Text('Settle Up'),
        icon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
