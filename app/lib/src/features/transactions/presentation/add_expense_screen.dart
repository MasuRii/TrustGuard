import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../ui/components/member_avatar_selector.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? transactionId;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.transactionId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  DateTime _occurredAt = DateTime.now();
  String? _payerMemberId;
  final Set<String> _selectedMemberIds = {};
  final Set<String> _selectedTagIds = {};
  final Map<String, TextEditingController> _customAmountControllers = {};
  SplitType _splitType = SplitType.equal;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _createdAt = DateTime.now();

  bool _isDifferentCurrency = false;
  String _originalCurrencyCode = 'USD';

  static const _commonCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'INR',
    'CHF',
    'CNY',
    'SGD',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _originalAmountController.dispose();
    _exchangeRateController.dispose();
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _occurredAt) {
      setState(() {
        _occurredAt = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payerMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a payer')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    final amountDouble = double.tryParse(_amountController.text);
    if (amountDouble == null || amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmountMinor = MoneyUtils.toMinorUnits(amountDouble);
      final participantCount = _selectedMemberIds.length;

      final List<int> splitAmounts;
      if (_splitType == SplitType.equal) {
        splitAmounts = MoneyUtils.splitEqual(
          totalAmountMinor,
          participantCount,
        );
      } else {
        // Custom split
        splitAmounts = _selectedMemberIds.map((id) {
          final controller = _customAmountControllers[id];
          if (controller == null) return 0;
          return MoneyUtils.toMinorUnits(double.tryParse(controller.text) ?? 0);
        }).toList();
      }

      final participantList = _selectedMemberIds.toList()..sort();
      final participants = <ExpenseParticipant>[];
      for (int i = 0; i < participantList.length; i++) {
        participants.add(
          ExpenseParticipant(
            memberId: participantList[i],
            owedAmountMinor: splitAmounts[i],
          ),
        );
      }

      final validation = Validators.validateExpense(
        totalAmountMinor: totalAmountMinor,
        participantAmountsMinor: splitAmounts,
      );

      if (!validation.isValid) {
        throw Exception(validation.errorMessage);
      }

      double? exchangeRate;
      String? originalCurrencyCode;
      int? originalAmountMinor;

      if (_isDifferentCurrency) {
        exchangeRate = double.tryParse(_exchangeRateController.text);
        originalCurrencyCode = _originalCurrencyCode;
        originalAmountMinor = MoneyUtils.toMinorUnits(
          double.tryParse(_originalAmountController.text) ?? 0,
        );
      }

      final repository = ref.read(transactionRepositoryProvider);
      final allTags = ref.read(tagsProvider(widget.groupId)).value ?? [];
      final selectedTags = allTags
          .where((t) => _selectedTagIds.contains(t.id))
          .toList();
      final now = DateTime.now();

      final transaction = Transaction(
        id: widget.transactionId ?? const Uuid().v4(),
        groupId: widget.groupId,
        type: TransactionType.expense,
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
        createdAt: widget.transactionId != null ? _createdAt : now,
        updatedAt: now,
        expenseDetail: ExpenseDetail(
          payerMemberId: _payerMemberId!,
          totalAmountMinor: totalAmountMinor,
          splitType: _splitType,
          participants: participants,
          exchangeRate: exchangeRate,
          originalCurrencyCode: originalCurrencyCode,
          originalAmountMinor: originalAmountMinor,
        ),
        tags: selectedTags,
      );

      if (widget.transactionId == null) {
        await repository.createTransaction(transaction);
      } else {
        await repository.updateTransaction(transaction);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateConvertedAmount() {
    final original = double.tryParse(_originalAmountController.text);
    final rate = double.tryParse(_exchangeRateController.text);
    if (original != null && rate != null) {
      setState(() {
        _amountController.text = (original * rate).toStringAsFixed(2);
      });
    }
  }

  void _calculateOriginalAmount() {
    final converted = double.tryParse(_amountController.text);
    final rate = double.tryParse(_exchangeRateController.text);
    if (converted != null && rate != null && rate > 0) {
      setState(() {
        _originalAmountController.text = (converted / rate).toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final isEdit = widget.transactionId != null;

    if (isEdit && !_isInitialized) {
      final txAsync = ref.watch(transactionProvider(widget.transactionId!));
      txAsync.whenData((tx) {
        if (tx != null && tx.expenseDetail != null) {
          final detail = tx.expenseDetail!;
          _amountController.text = MoneyUtils.fromMinorUnits(
            detail.totalAmountMinor,
          ).toStringAsFixed(2);
          _noteController.text = tx.note;
          _occurredAt = tx.occurredAt;
          _createdAt = tx.createdAt;
          _payerMemberId = detail.payerMemberId;
          _splitType = detail.splitType;

          if (detail.exchangeRate != null) {
            _isDifferentCurrency = true;
            _exchangeRateController.text = detail.exchangeRate!.toString();
            _originalCurrencyCode = detail.originalCurrencyCode ?? 'USD';
            if (detail.originalAmountMinor != null) {
              _originalAmountController.text = MoneyUtils.fromMinorUnits(
                detail.originalAmountMinor!,
              ).toStringAsFixed(2);
            }
          }

          _selectedMemberIds.clear();
          for (var p in detail.participants) {
            _selectedMemberIds.add(p.memberId);
            if (_splitType == SplitType.custom) {
              _customAmountControllers[p.memberId] = TextEditingController(
                text: MoneyUtils.fromMinorUnits(
                  p.owedAmountMinor,
                ).toStringAsFixed(2),
              );
            }
          }
          _selectedTagIds.clear();
          _selectedTagIds.addAll(tx.tags.map((t) => t.id));
          _isInitialized = true;
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Add members to the group first'));
          }

          if (!_isInitialized && !isEdit) {
            // Default to first member as payer and all members as participants
            _payerMemberId ??= members.first.id;
            if (_selectedMemberIds.isEmpty) {
              _selectedMemberIds.addAll(members.map((m) => m.id));
            }
            _isInitialized = true;
          }

          return groupAsync.when(
            data: (group) {
              final currency = group?.currencyCode ?? 'USD';
              return _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCurrencySection(currency),
                            const SizedBox(height: AppTheme.space16),
                            Semantics(
                              label: 'Expense amount in $currency',
                              child: TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: _isDifferentCurrency
                                      ? 'Converted Amount ($currency)'
                                      : 'Amount',
                                  prefixText: '$currency ',
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (value) {
                                  if (_isDifferentCurrency) {
                                    _calculateOriginalAmount();
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                autofocus: !isEdit,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                            Semantics(
                              label: 'Expense note',
                              child: TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                  hintText: 'What was this for?',
                                  border: OutlineInputBorder(),
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                            Semantics(
                              label: 'Expense date',
                              button: true,
                              child: ListTile(
                                title: const Text('Date'),
                                subtitle: Text(
                                  DateFormat.yMMMd().format(_occurredAt),
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => _selectDate(context),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.space16),
                            _buildTagsSection(),
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
                            const SizedBox(height: AppTheme.space24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Split between',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                DropdownButton<SplitType>(
                                  value: _splitType,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: SplitType.equal,
                                      child: Text('Split Equally'),
                                    ),
                                    DropdownMenuItem(
                                      value: SplitType.custom,
                                      child: Text('Split Customly'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _splitType = value;
                                        if (_splitType == SplitType.custom) {
                                          // Initialize custom controllers if needed
                                          for (var id in _selectedMemberIds) {
                                            _customAmountControllers
                                                .putIfAbsent(
                                                  id,
                                                  () => TextEditingController(),
                                                );
                                          }
                                        }
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: members.map((m) {
                                  final isSelected = _selectedMemberIds
                                      .contains(m.id);
                                  return Column(
                                    children: [
                                      CheckboxListTile(
                                        title: Text(m.displayName),
                                        value: isSelected,
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedMemberIds.add(m.id);
                                              if (_splitType ==
                                                  SplitType.custom) {
                                                _customAmountControllers
                                                    .putIfAbsent(
                                                      m.id,
                                                      () =>
                                                          TextEditingController(),
                                                    );
                                              }
                                            } else {
                                              _selectedMemberIds.remove(m.id);
                                            }
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                      if (isSelected &&
                                          _splitType == SplitType.custom)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 64.0,
                                            right: 16.0,
                                            bottom: 8.0,
                                          ),
                                          child: TextFormField(
                                            controller:
                                                _customAmountControllers[m.id],
                                            decoration: InputDecoration(
                                              labelText: 'Amount',
                                              prefixText: '$currency ',
                                              isDense: true,
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            if (_splitType == SplitType.custom) ...[
                              const SizedBox(height: AppTheme.space8),
                              _buildCustomSplitStatus(currency),
                            ],
                            const SizedBox(height: AppTheme.space32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                isEdit ? 'Update Expense' : 'Add Expense',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading group: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading members: $e')),
      ),
    );
  }

  Widget _buildCurrencySection(String groupCurrency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Different Currency?'),
          subtitle: const Text('Record expense in another currency'),
          value: _isDifferentCurrency,
          onChanged: (value) {
            setState(() {
              _isDifferentCurrency = value;
              if (_isDifferentCurrency &&
                  _exchangeRateController.text.isEmpty) {
                _exchangeRateController.text = '1.0';
                _originalAmountController.text = _amountController.text;
              }
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_isDifferentCurrency) ...[
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _originalCurrencyCode,
                  items: _commonCurrencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _originalCurrencyCode = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _originalAmountController,
                  decoration: InputDecoration(
                    labelText: 'Original Amount',
                    prefixText: '$_originalCurrencyCode ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) => _calculateConvertedAmount(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          TextFormField(
            controller: _exchangeRateController,
            decoration: InputDecoration(
              labelText: 'Exchange Rate',
              helperText: '1 $_originalCurrencyCode = ? $groupCurrency',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => _calculateConvertedAmount(),
          ),
          const SizedBox(height: AppTheme.space8),
          if (double.tryParse(_exchangeRateController.text) != null &&
              double.tryParse(_originalAmountController.text) != null)
            Text(
              'Preview: ${_originalAmountController.text} $_originalCurrencyCode × ${_exchangeRateController.text} = '
              '${(double.tryParse(_originalAmountController.text)! * double.tryParse(_exchangeRateController.text)!).toStringAsFixed(2)} $groupCurrency',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTagsSection() {
    final tagsAsync = ref.watch(tagsProvider(widget.groupId));

    return tagsAsync.when(
      data: (List<Tag> tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tags', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: tags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                return FilterChip(
                  label: Text(tag.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTagIds.add(tag.id);
                      } else {
                        _selectedTagIds.remove(tag.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCustomSplitStatus(String currency) {
    final formatMoney = ref.watch(moneyFormatterProvider);
    final totalAmountMinor = MoneyUtils.toMinorUnits(
      double.tryParse(_amountController.text) ?? 0,
    );
    final customTotalMinor = _selectedMemberIds.fold<int>(0, (sum, id) {
      final text = _customAmountControllers[id]?.text ?? '0';
      return sum + MoneyUtils.toMinorUnits(double.tryParse(text) ?? 0);
    });

    final difference = totalAmountMinor - customTotalMinor;
    final isCorrect = difference == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withAlpha(25)
            : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isCorrect ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isCorrect ? 'Total matches!' : 'Total mismatch',
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isCorrect
                ? formatMoney(totalAmountMinor, currencyCode: currency)
                : '${difference > 0 ? 'Remaining' : 'Over'}: ${formatMoney(difference.abs(), currencyCode: currency)}',
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
