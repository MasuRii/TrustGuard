import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../core/services/keyboard_shortcut_service.dart';
import '../../../core/models/transfer.dart';
import '../../../core/models/recurring_transaction.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../ui/animations/shake_widget.dart';
import '../../../ui/components/amount_input_field.dart';
import '../../../ui/components/amount_suggestion_chips.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class AddTransferScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? transactionId;
  final String? initialFromId;
  final String? initialToId;
  final String? initialAmount;
  final String? initialNote;

  const AddTransferScreen({
    super.key,
    required this.groupId,
    this.transactionId,
    this.initialFromId,
    this.initialToId,
    this.initialAmount,
    this.initialNote,
  });

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final _saveButtonKey = GlobalKey<ShakeWidgetState>();
  final _appBarSaveKey = GlobalKey<ShakeWidgetState>();

  DateTime _occurredAt = DateTime.now();
  String? _fromMemberId;
  String? _toMemberId;
  final Set<String> _selectedTagIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _createdAt = DateTime.now();

  bool _isRepeatEnabled = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  DateTime? _endDate;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
    if (!_formKey.currentState!.validate()) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      return;
    }
    if (_fromMemberId == null || _toMemberId == null) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both members')),
      );
      return;
    }

    final amountDouble = double.tryParse(_amountController.text);
    if (amountDouble == null || amountDouble <= 0) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final amountMinor = MoneyUtils.toMinorUnits(amountDouble);
    final validation = Validators.validateTransfer(
      fromMemberId: _fromMemberId!,
      toMemberId: _toMemberId!,
      amountMinor: amountMinor,
    );

    if (!validation.isValid) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation.errorMessage!)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(transactionRepositoryProvider);
      final allTags = ref.read(tagsProvider(widget.groupId)).value ?? [];
      final selectedTags = allTags
          .where((t) => _selectedTagIds.contains(t.id))
          .toList();
      final now = DateTime.now();

      final transaction = Transaction(
        id: widget.transactionId ?? const Uuid().v4(),
        groupId: widget.groupId,
        type: TransactionType.transfer,
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
        createdAt: widget.transactionId != null ? _createdAt : now,
        updatedAt: now,
        isRecurring: _isRepeatEnabled,
        transferDetail: TransferDetail(
          fromMemberId: _fromMemberId!,
          toMemberId: _toMemberId!,
          amountMinor: amountMinor,
        ),
        tags: selectedTags,
      );

      if (widget.transactionId == null) {
        await repository.createTransaction(transaction);

        if (_isRepeatEnabled) {
          final recurrenceService = ref.read(recurrenceServiceProvider);
          final nextOccurrence = recurrenceService.calculateNextOccurrence(
            _occurredAt,
            _frequency,
          );

          final recurringTx = RecurringTransaction(
            id: const Uuid().v4(),
            groupId: widget.groupId,
            templateTransactionId: transaction.id,
            frequency: _frequency,
            nextOccurrence: nextOccurrence,
            endDate: _endDate,
            createdAt: now,
          );

          await ref
              .read(recurringTransactionRepositoryProvider)
              .createRecurring(recurringTx);
        }
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
        ).showSnackBar(SnackBar(content: Text('Error saving transfer: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(context.l10n.repeat),
          value: _isRepeatEnabled,
          onChanged: (value) => setState(() => _isRepeatEnabled = value),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isRepeatEnabled) ...[
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RecurrenceFrequency>(
                  key: ValueKey('frequency_$_isInitialized'),
                  initialValue: _frequency,
                  decoration: InputDecoration(
                    labelText: context.l10n.frequency,
                    border: const OutlineInputBorder(),
                  ),
                  items: RecurrenceFrequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(_getFrequencyLabel(f)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _frequency = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _endDate ?? _occurredAt.add(const Duration(days: 30)),
                      firstDate: _occurredAt,
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    _endDate == null
                        ? context.l10n.repeatForever
                        : DateFormat.yMMMd().format(_endDate!),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              if (_endDate != null)
                IconButton(
                  onPressed: () => setState(() => _endDate = null),
                  icon: const Icon(Icons.clear),
                  tooltip: context.l10n.repeatForever,
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.minTouchTarget,
                    minHeight: AppTheme.minTouchTarget,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _getFrequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return context.l10n.daily;
      case RecurrenceFrequency.weekly:
        return context.l10n.weekly;
      case RecurrenceFrequency.biweekly:
        return context.l10n.biweekly;
      case RecurrenceFrequency.monthly:
        return context.l10n.monthly;
      case RecurrenceFrequency.yearly:
        return context.l10n.yearly;
    }
  }

  Widget _buildAmountSuggestions(
    AsyncValue<List<int>> suggestionsAsync,
    String currency,
  ) {
    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space8),
          child: AmountSuggestionChips(
            suggestions: suggestions,
            currencyCode: currency,
            onSelected: (amount) {
              setState(() {
                _amountController.text = MoneyUtils.fromMinorUnits(
                  amount,
                ).toStringAsFixed(2);
              });
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final suggestionsAsync = ref.watch(
      amountSuggestionsProvider(widget.groupId),
    );
    final useCustomKeypad = ref.watch(customKeypadProvider);
    final isEdit = widget.transactionId != null;

    if (isEdit && !_isInitialized) {
      final txAsync = ref.watch(transactionProvider(widget.transactionId!));
      txAsync.whenData((tx) {
        if (tx != null && tx.transferDetail != null) {
          _amountController.text = MoneyUtils.fromMinorUnits(
            tx.transferDetail!.amountMinor,
          ).toStringAsFixed(2);
          _noteController.text = tx.note;
          _occurredAt = tx.occurredAt;
          _createdAt = tx.createdAt;
          _fromMemberId = tx.transferDetail!.fromMemberId;
          _toMemberId = tx.transferDetail!.toMemberId;
          _selectedTagIds.clear();
          _selectedTagIds.addAll(tx.tags.map((t) => t.id));

          _isRepeatEnabled = tx.isRecurring;
          if (_isRepeatEnabled) {
            ref.read(recurringByTemplateProvider(tx.id)).whenData((recurring) {
              if (recurring != null) {
                setState(() {
                  _frequency = recurring.frequency;
                  _endDate = recurring.endDate;
                });
              }
            });
          }

          _isInitialized = true;
          setState(() {});
        }
      });
    }

    return Actions(
      actions: {
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (intent) {
            _save();
            return null;
          },
        ),
        CancelIntent: CallbackAction<CancelIntent>(
          onInvoke: (intent) {
            context.pop();
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Transfer' : 'Add Transfer'),
          actions: [
            if (!_isLoading)
              ShakeWidget(
                key: _appBarSaveKey,
                child: IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  tooltip: 'Save',
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.minTouchTarget,
                    minHeight: AppTheme.minTouchTarget,
                  ),
                ),
              ),
          ],
        ),
        body: membersAsync.when(
          data: (members) {
            if (members.length < 2) {
              return const Center(
                child: Text('Add at least two members to the group first'),
              );
            }

            if (!_isInitialized && !isEdit) {
              _fromMemberId =
                  widget.initialFromId ??
                  (members.isNotEmpty ? members[0].id : null);
              _toMemberId =
                  widget.initialToId ??
                  (members.length > 1 ? members[1].id : null);
              if (widget.initialAmount != null) {
                _amountController.text = widget.initialAmount!;
              }
              if (widget.initialNote != null) {
                _noteController.text = widget.initialNote!;
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
                              _buildAmountSuggestions(
                                suggestionsAsync,
                                currency,
                              ),
                              if (useCustomKeypad) ...[
                                Card(
                                  margin: const EdgeInsets.only(
                                    bottom: AppTheme.space24,
                                  ),
                                  elevation: 0,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: AmountInputField(
                                    key: ValueKey(
                                      'amount_${_amountController.text}',
                                    ),
                                    initialValue: MoneyUtils.toMinorUnits(
                                      double.tryParse(_amountController.text) ??
                                          0,
                                    ),
                                    currencyCode: currency,
                                    onChanged: (value) {
                                      _amountController.text =
                                          MoneyUtils.fromMinorUnits(
                                            value,
                                          ).toStringAsFixed(2);
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                              if (!useCustomKeypad) ...[
                                Semantics(
                                  label: 'Transfer amount in $currency',
                                  child: TextFormField(
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
                                ),
                              ],
                              const SizedBox(height: AppTheme.space16),
                              Semantics(
                                label: 'Transfer note',
                                child: TextFormField(
                                  controller: _noteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Note',
                                    hintText: 'e.g. Settlement',
                                    border: OutlineInputBorder(),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Semantics(
                                label: 'Transfer date',
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
                              _buildRepeatSection(),

                              const SizedBox(height: AppTheme.space16),

                              _buildTagsSection(),
                              const SizedBox(height: AppTheme.space24),
                              Text(
                                'From',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTheme.space8),
                              DropdownButtonFormField<String>(
                                initialValue: _fromMemberId,
                                items: members.map((m) {
                                  return DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.displayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _fromMemberId = value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Text(
                                'To',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTheme.space8),
                              DropdownButtonFormField<String>(
                                initialValue: _toMemberId,
                                items: members.map((m) {
                                  return DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.displayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _toMemberId = value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.space32),
                              ShakeWidget(
                                key: _saveButtonKey,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(
                                    isEdit ? 'Update Transfer' : 'Add Transfer',
                                  ),
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
      ),
    );
  }
}
