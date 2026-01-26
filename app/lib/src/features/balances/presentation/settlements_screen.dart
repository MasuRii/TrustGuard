import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/settlement_suggestion.dart';
import '../../../core/utils/money.dart';
import '../../../ui/animations/animation_config.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/skeletons/skeleton_list.dart';
import '../../groups/presentation/groups_providers.dart';
import '../providers/balance_providers.dart';
import '../services/balance_service.dart';

class SettlementsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettlementsScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(groupBalancesProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final selfMemberId = ref.watch(groupSelfMemberProvider(widget.groupId));
    final formatMoney = ref.watch(moneyFormatterProvider);
    final l10n = context.l10n;

    ref.listen(settlementSuggestionsProvider(widget.groupId), (previous, next) {
      if (previous != null && previous.isNotEmpty && next.isEmpty) {
        if (!AnimationConfig.useReducedMotion(context)) {
          _confettiController.play();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settlements)),
      body: Stack(
        children: [
          groupAsync.when(
            data: (group) {
              final currency = group?.currencyCode ?? 'USD';
              return balancesAsync.when(
                data: (balances) {
                  final suggestions = ref.watch(
                    settlementSuggestionsProvider(widget.groupId),
                  );

                  if (suggestions.isEmpty) {
                    return EmptyState(
                      svgPath: 'assets/illustrations/all_settled.svg',
                      icon: Icons.check_circle_outline,
                      title: l10n.allSettledUp,
                      message: '', // Message is optional or can be empty
                    );
                  }

                  final actionRequired = suggestions
                      .where((s) => s.fromMemberId == selfMemberId)
                      .toList();
                  final incoming = suggestions
                      .where((s) => s.toMemberId == selfMemberId)
                      .toList();
                  final other = suggestions
                      .where(
                        (s) =>
                            s.fromMemberId != selfMemberId &&
                            s.toMemberId != selfMemberId,
                      )
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    children: [
                      if (selfMemberId == null)
                        _buildSelfMemberSelector(
                          context,
                          ref,
                          widget.groupId,
                          membersAsync,
                        ),
                      if (actionRequired.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          l10n.actionRequired,
                          Colors.red,
                        ),
                        ...actionRequired.map(
                          (s) => _SuggestionCard(
                            suggestion: s,
                            groupId: widget.groupId,
                            currency: currency,
                            formatMoney: formatMoney,
                            isOutgoing: true,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],
                      if (incoming.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          l10n.incoming,
                          Colors.green,
                        ),
                        ...incoming.map(
                          (s) => _SuggestionCard(
                            suggestion: s,
                            groupId: widget.groupId,
                            currency: currency,
                            formatMoney: formatMoney,
                            isIncoming: true,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],
                      if (other.isNotEmpty)
                        ExpansionTile(
                          title: Text(l10n.otherSettlements),
                          initiallyExpanded: selfMemberId == null,
                          children: other
                              .map(
                                (s) => _SuggestionCard(
                                  suggestion: s,
                                  groupId: widget.groupId,
                                  currency: currency,
                                  formatMoney: formatMoney,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  );
                },
                loading: () => const SkeletonList(),
                error: (e, _) =>
                    Center(child: Text('Error loading balances: $e')),
              );
            },
            loading: () => const SkeletonList(),
            error: (e, _) => Center(child: Text('Error loading group: $e')),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSelfMemberSelector(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    AsyncValue<List<Member>> membersAsync,
  ) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.whichOneIsYou,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              l10n.selectSelfMember,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.space8),
            membersAsync.when(
              data: (members) => Wrap(
                spacing: AppTheme.space8,
                children: members.map((member) {
                  return ActionChip(
                    label: Text(member.displayName),
                    onPressed: () {
                      ref
                          .read(groupSelfMemberProvider(groupId).notifier)
                          .setSelfMember(member.id);
                    },
                  );
                }).toList(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final SettlementSuggestion suggestion;
  final String groupId;
  final String currency;
  final MoneyFormatter formatMoney;
  final bool isOutgoing;
  final bool isIncoming;

  const _SuggestionCard({
    required this.suggestion,
    required this.groupId,
    required this.currency,
    required this.formatMoney,
    this.isOutgoing = false,
    this.isIncoming = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.fromMemberName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.owesLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        suggestion.toMemberName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.isOwedLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.space24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatMoney(suggestion.amountMinor, currencyCode: currency),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isOutgoing
                        ? Colors.red
                        : isIncoming
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.push(
                      '/group/$groupId/transactions/add-transfer'
                      '?fromId=${suggestion.fromMemberId}'
                      '&toId=${suggestion.toMemberId}'
                      '&amount=${MoneyUtils.fromMinorUnits(suggestion.amountMinor)}'
                      '&note=Settlement',
                    );
                  },
                  child: Text(
                    isOutgoing
                        ? l10n.payNow
                        : isIncoming
                        ? l10n.markAsPaid
                        : l10n.record,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
