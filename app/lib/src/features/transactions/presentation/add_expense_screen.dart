import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
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
  DateTime _occurredAt = DateTime.now();
  String? _payerMemberId;
  final Set<String> _selectedMemberIds = {};
  final Set<String> _selectedTagIds = {};
  final Map<String, TextEditingController> _customAmountControllers = {};
  SplitType _splitType = SplitType.equal;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _createdAt = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final isEdit = widget.transactionId != null;

    if (isEdit && !_isInitialized) {
      final txAsync = ref.watch(transactionProvider(widget.transactionId!));
      txAsync.whenData((tx) {
        if (tx != null && tx.expenseDetail != null) {
          _amountController.text = MoneyUtils.fromMinorUnits(
            tx.expenseDetail!.totalAmountMinor,
          ).toStringAsFixed(2);
          _noteController.text = tx.note;
          _occurredAt = tx.occurredAt;
          _createdAt = tx.createdAt;
          _payerMemberId = tx.expenseDetail!.payerMemberId;
          _splitType = tx.expenseDetail!.splitType;
          _selectedMemberIds.clear();
          for (var p in tx.expenseDetail!.participants) {
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
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '$currency ',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
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
                            const SizedBox(height: AppTheme.space16),
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note',
                                hintText: 'What was this for?',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: AppTheme.space16),
                            ListTile(
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
                            const SizedBox(height: AppTheme.space16),
                            _buildTagsSection(),
                            const SizedBox(height: AppTheme.space24),
                            Text(
                              'Paid by',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.space8),
                            DropdownButtonFormField<String>(
                              initialValue: _payerMemberId,
                              items: members.map((m) {
                                return DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _payerMemberId = value);
                                }
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCustomSplitStatus(String currency) {
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
                ? MoneyUtils.format(totalAmountMinor, currencyCode: currency)
                : '${difference > 0 ? 'Remaining' : 'Over'}: ${MoneyUtils.format(difference.abs(), currencyCode: currency)}',
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
