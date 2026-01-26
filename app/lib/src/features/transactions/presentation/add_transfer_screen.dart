import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/transfer.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
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
  DateTime _occurredAt = DateTime.now();
  String? _fromMemberId;
  String? _toMemberId;
  final Set<String> _selectedTagIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _createdAt = DateTime.now();

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
    if (!_formKey.currentState!.validate()) return;
    if (_fromMemberId == null || _toMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both members')),
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

    final amountMinor = MoneyUtils.toMinorUnits(amountDouble);
    final validation = Validators.validateTransfer(
      fromMemberId: _fromMemberId!,
      toMemberId: _toMemberId!,
      amountMinor: amountMinor,
    );

    if (!validation.isValid) {
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
        transferDetail: TransferDetail(
          fromMemberId: _fromMemberId!,
          toMemberId: _toMemberId!,
          amountMinor: amountMinor,
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
        ).showSnackBar(SnackBar(content: Text('Error saving transfer: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
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
          _isInitialized = true;
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transfer' : 'Add Transfer'),
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
                                hintText: 'e.g. Settlement',
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
                            ElevatedButton(
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
}
