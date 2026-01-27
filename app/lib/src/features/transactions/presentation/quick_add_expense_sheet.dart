import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app.dart';
import '../../../app/providers.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/money.dart';
import '../../../ui/animations/shake_widget.dart';
import '../../../ui/components/amount_input_field.dart';
import '../../../ui/components/member_avatar_selector.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';

class QuickAddExpenseSheet extends ConsumerStatefulWidget {
  final String groupId;
  final VoidCallback? onSuccess;

  const QuickAddExpenseSheet({
    super.key,
    required this.groupId,
    this.onSuccess,
  });

  @override
  ConsumerState<QuickAddExpenseSheet> createState() =>
      _QuickAddExpenseSheetState();
}

class _QuickAddExpenseSheetState extends ConsumerState<QuickAddExpenseSheet> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  int _amountMinor = 0;
  String? _payerMemberId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickExpense() async {
    if (_amountMinor <= 0) {
      _shakeKey.currentState?.shake();
      HapticsService.warning();
      return;
    }

    final members =
        ref.read(membersByGroupProvider(widget.groupId)).value ?? [];
    if (members.isEmpty || _payerMemberId == null) {
      _shakeKey.currentState?.shake();
      HapticsService.warning();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final participantCount = members.length;
      final splitAmounts = MoneyUtils.splitEqual(
        _amountMinor,
        participantCount,
      );

      final sortedMembers = members.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final participants = <ExpenseParticipant>[];
      for (int i = 0; i < sortedMembers.length; i++) {
        participants.add(
          ExpenseParticipant(
            memberId: sortedMembers[i].id,
            owedAmountMinor: splitAmounts[i],
          ),
        );
      }

      final now = DateTime.now();
      final transaction = Transaction(
        id: const Uuid().v4(),
        groupId: widget.groupId,
        type: TransactionType.expense,
        occurredAt: now,
        note: _noteController.text.trim().isEmpty
            ? 'Quick Add'
            : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
        expenseDetail: ExpenseDetail(
          payerMemberId: _payerMemberId!,
          totalAmountMinor: _amountMinor,
          splitType: SplitType.equal,
          participants: participants,
        ),
      );

      await ref
          .read(transactionRepositoryProvider)
          .createTransaction(transaction);

      HapticsService.success();

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final useCustomKeypad = ref.watch(customKeypadProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return membersAsync.when(
      data: (members) {
        if (!_isInitialized && members.isNotEmpty) {
          _payerMemberId = members.first.id;
          _isInitialized = true;
        }

        return groupAsync.when(
          data: (group) {
            final currency = group?.currencyCode ?? 'USD';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space24,
                AppTheme.space16,
                AppTheme.space24,
                AppTheme.space24 + bottomInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.quickAdd,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    context.l10n.quickAddHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  ShakeWidget(
                    key: _shakeKey,
                    child: Column(
                      children: [
                        if (useCustomKeypad)
                          AmountInputField(
                            initialValue: _amountMinor,
                            currencyCode: currency,
                            onChanged: (value) =>
                                setState(() => _amountMinor = value),
                            showQuickButtons: true,
                            showKeypad: true,
                          )
                        else
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '$currency ',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final double? val = double.tryParse(value);
                              if (val != null) {
                                setState(
                                  () => _amountMinor = MoneyUtils.toMinorUnits(
                                    val,
                                  ),
                                );
                              } else {
                                setState(() => _amountMinor = 0);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'What was this for?',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppTheme.space24),
                  MemberAvatarSelector(
                    label: context.l10n.paidBy,
                    members: members,
                    selectedIds: _payerMemberId != null
                        ? {_payerMemberId!}
                        : {},
                    onSelectionChanged: (ids) {
                      if (ids.isNotEmpty) {
                        setState(() => _payerMemberId = ids.first);
                      }
                    },
                    allowMultiple: false,
                  ),
                  const SizedBox(height: AppTheme.space32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveQuickExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.save),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
