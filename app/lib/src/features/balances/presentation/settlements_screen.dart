import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/money.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import '../services/balance_service.dart';
import '../services/settlement_service.dart';

class SettlementsScreen extends ConsumerWidget {
  final String groupId;

  const SettlementsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Suggestions')),
      body: groupAsync.when(
        data: (group) {
          final currency = group?.currencyCode ?? 'USD';
          return balancesAsync.when(
            data: (balances) {
              final suggestions =
                  SettlementService.computeSettlementSuggestions(balances);

              if (suggestions.isEmpty) {
                return const Center(
                  child: Text('All settled up! No suggestions needed.'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Text(
                      'Suggested transfers to reach zero balances for everyone.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.space12,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.fromMemberName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'owes',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            suggestion.toMemberName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'is owed',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: AppTheme.space24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      MoneyUtils.format(
                                        suggestion.amountMinor,
                                        currencyCode: currency,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navigate to Add Transfer screen with pre-filled values
                                        context.push(
                                          '/group/$groupId/transactions/add-transfer'
                                          '?fromId=${suggestion.fromMemberId}'
                                          '&toId=${suggestion.toMemberId}'
                                          '&amount=${MoneyUtils.fromMinorUnits(suggestion.amountMinor)}'
                                          '&note=Settlement',
                                        );
                                      },
                                      child: const Text('Record'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading balances: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading group: $e')),
      ),
    );
  }
}
