import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/components/balance_progress_bar.dart';
import '../../../ui/components/skeletons/skeleton_list.dart';
import '../../../ui/animations/staggered_list_animation.dart';
import '../../../core/utils/haptics.dart';
import '../../groups/presentation/groups_providers.dart';
import '../services/balance_service.dart';

class BalancesScreen extends ConsumerStatefulWidget {
  final String groupId;

  const BalancesScreen({super.key, required this.groupId});

  @override
  ConsumerState<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends ConsumerState<BalancesScreen>
    with SingleTickerProviderStateMixin {
  StaggeredListAnimationController? _staggeredController;
  int _lastItemCount = 0;

  @override
  void dispose() {
    _staggeredController?.dispose();
    super.dispose();
  }

  void _updateAnimationController(int count) {
    if (_staggeredController != null && _lastItemCount == count) {
      _staggeredController?.reset();
      _staggeredController?.startAnimation();
      return;
    }

    if (mounted) {
      setState(() {
        _staggeredController?.dispose();
        _staggeredController = StaggeredListAnimationController(
          vsync: this,
          itemCount: count,
        );
        _lastItemCount = count;
      });
      _staggeredController!.startAnimation();
    }
  }

  Future<void> _onRefresh() async {
    HapticsService.lightTap();
    ref.invalidate(groupBalancesProvider(widget.groupId));
    await ref.read(groupBalancesProvider(widget.groupId).future);
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(groupBalancesProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final formatMoney = ref.watch(moneyFormatterProvider);

    // Restart animation when data changes
    ref.listen(groupBalancesProvider(widget.groupId), (previous, next) {
      next.whenData((balances) {
        if (balances.isNotEmpty) {
          _updateAnimationController(balances.length);
        }
      });
    });

    // Initial load check
    balancesAsync.whenData((balances) {
      if (balances.isNotEmpty && _staggeredController == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateAnimationController(balances.length);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.balance)),
      body: groupAsync.when(
        data: (group) {
          final currency = group?.currencyCode ?? 'USD';
          return balancesAsync.when(
            data: (balances) {
              if (balances.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: EmptyState(
                        icon: Icons.calculate_outlined,
                        title: context.l10n.calculating,
                        message: '',
                      ),
                    ),
                  ),
                );
              }

              // Sort balances: creditors first, then settled, then debtors
              final sortedBalances = List.of(balances)
                ..sort((a, b) => b.netAmountMinor.compareTo(a.netAmountMinor));

              final maxAmount = sortedBalances.fold<int>(
                0,
                (max, b) =>
                    b.netAmountMinor.abs() > max ? b.netAmountMinor.abs() : max,
              );

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sortedBalances.length,
                  itemBuilder: (context, index) {
                    final balance = sortedBalances[index];
                    final isSettled = balance.netAmountMinor == 0;
                    final isCreditor = balance.netAmountMinor > 0;

                    final card = Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.space8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(
                                balance.memberName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                isSettled
                                    ? context.l10n.settled
                                    : isCreditor
                                    ? context.l10n.isOwedLabel
                                    : context.l10n.owesLabel,
                              ),
                              trailing: Text(
                                formatMoney(
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space16,
                              ),
                              child: BalanceProgressBar(
                                amount: balance.netAmountMinor,
                                maxAmount: maxAmount,
                                currencyCode: currency,
                                formatMoney: formatMoney,
                                showLabel: false,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                          ],
                        ),
                      ),
                    );

                    if (_staggeredController != null) {
                      return StaggeredListItem(
                        animation: _staggeredController!.getAnimation(index),
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
              );
            },
            loading: () => const SkeletonList(),
            error: (e, _) => Center(child: Text('Error loading balances: $e')),
          );
        },
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('Error loading group: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/${widget.groupId}/settlements'),
        label: Text(context.l10n.settlements),
        icon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
