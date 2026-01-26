import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/member.dart';
import '../../../core/models/recurring_transaction.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../ui/animations/shake_widget.dart';
import '../../../ui/components/member_avatar_selector.dart';
import '../../../ui/theme/app_theme.dart';
import '../../ocr/models/receipt_data.dart';
import '../../ocr/providers/ocr_providers.dart';
import 'widgets/split_preview_bar.dart';
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

  final _saveButtonKey = GlobalKey<ShakeWidgetState>();
  final _appBarSaveKey = GlobalKey<ShakeWidgetState>();
  final _splitPreviewKey = GlobalKey<ShakeWidgetState>();

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

  bool _isRepeatEnabled = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  DateTime? _endDate;

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final scanner = ref.read(receiptScannerServiceProvider);
      final data = await scanner.scanReceipt(image.path);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (data != null) {
        _showOcrResultDialog(data);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not scan receipt')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning receipt: $e')));
    }
  }

  void _showOcrResultDialog(ReceiptData data) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.scanReceipt),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.suggestedMerchant != null) ...[
              Text('Merchant:', style: Theme.of(context).textTheme.labelSmall),
              Text(
                data.suggestedMerchant!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
            ],
            if (data.suggestedAmount != null) ...[
              Text('Amount:', style: Theme.of(context).textTheme.labelSmall),
              Text(
                data.suggestedAmount!.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
            ],
            if (data.suggestedDate != null) ...[
              Text('Date:', style: Theme.of(context).textTheme.labelSmall),
              Text(
                DateFormat.yMMMd().format(data.suggestedDate!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(
                  data.confidence > 0.8
                      ? Icons.verified
                      : (data.confidence > 0.4 ? Icons.info : Icons.warning),
                  size: 16,
                  color: data.confidence > 0.8
                      ? Colors.green
                      : (data.confidence > 0.4 ? Colors.orange : Colors.red),
                ),
                const SizedBox(width: 4),
                Text(
                  data.confidence > 0.8
                      ? context.l10n.ocrConfidenceHigh
                      : (data.confidence > 0.4
                            ? context.l10n.ocrConfidenceMedium
                            : context.l10n.ocrConfidenceLow),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: data.confidence > 0.8
                        ? Colors.green
                        : (data.confidence > 0.4 ? Colors.orange : Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (data.suggestedAmount != null) {
                  _amountController.text = data.suggestedAmount!
                      .toStringAsFixed(2);
                }
                if (data.suggestedMerchant != null) {
                  _noteController.text = data.suggestedMerchant!;
                }
                if (data.suggestedDate != null) {
                  _occurredAt = data.suggestedDate!;
                }
              });
              Navigator.pop(context);
            },
            child: Text(context.l10n.applyScannedData),
          ),
        ],
      ),
    );
  }

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
    if (!_formKey.currentState!.validate()) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      return;
    }
    if (_payerMemberId == null) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a payer')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      _saveButtonKey.currentState?.shake();
      _appBarSaveKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
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
        _saveButtonKey.currentState?.shake();
        _appBarSaveKey.currentState?.shake();
        _splitPreviewKey.currentState?.shake();
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
        isRecurring: _isRepeatEnabled,
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

      HapticsService.success();

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

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isLoading) ...[
            IconButton(
              onPressed: _scanReceipt,
              icon: const Icon(Icons.document_scanner),
              tooltip: context.l10n.scanReceipt,
            ),
            ShakeWidget(
              key: _appBarSaveKey,
              child: IconButton(
                onPressed: _save,
                icon: const Icon(Icons.check),
                tooltip: 'Save',
              ),
            ),
          ],
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
                            _buildRepeatSection(),

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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space16,
                                  ),
                                  child: Text(
                                    context.l10n.splitBetween,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                DropdownButton<SplitType>(
                                  value: _splitType,
                                  underline: const SizedBox(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space16,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: SplitType.equal,
                                      child: Text(context.l10n.splitEqually),
                                    ),
                                    DropdownMenuItem(
                                      value: SplitType.custom,
                                      child: Text(context.l10n.splitCustomly),
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
                            MemberAvatarSelector(
                              members: members,
                              selectedIds: _selectedMemberIds,
                              onSelectionChanged: (ids) {
                                setState(() {
                                  _selectedMemberIds.clear();
                                  _selectedMemberIds.addAll(ids);
                                  if (_splitType == SplitType.custom) {
                                    for (var id in _selectedMemberIds) {
                                      _customAmountControllers.putIfAbsent(
                                        id,
                                        () => TextEditingController(),
                                      );
                                    }
                                    _customAmountControllers.removeWhere(
                                      (id, _) =>
                                          !_selectedMemberIds.contains(id),
                                    );
                                  }
                                });
                              },
                              allowMultiple: true,
                            ),
                            if (_splitType == SplitType.custom &&
                                _selectedMemberIds.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.space16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space16,
                                ),
                                child: Column(
                                  children: _selectedMemberIds.map((id) {
                                    final member = members.firstWhere(
                                      (m) => m.id == id,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppTheme.space12,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: Text(
                                              _getInitials(member.displayName),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppTheme.space12,
                                          ),
                                          Expanded(
                                            child: Text(
                                              member.displayName,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: TextFormField(
                                              controller:
                                                  _customAmountControllers[id],
                                              decoration: InputDecoration(
                                                labelText: 'Amount',
                                                prefixText: '$currency ',
                                                isDense: true,
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              onChanged: (_) => setState(() {}),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Required';
                                                }
                                                if (double.tryParse(value) ==
                                                    null) {
                                                  return 'Invalid';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            if (_selectedMemberIds.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.space16),
                              ShakeWidget(
                                key: _splitPreviewKey,
                                child: _buildSplitPreview(currency, members),
                              ),
                            ],
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
                                  isEdit ? 'Update Expense' : 'Add Expense',
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
                    HapticsService.selection();
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

  Widget _buildSplitPreview(String currency, List<Member> members) {
    final totalAmountMinor = MoneyUtils.toMinorUnits(
      double.tryParse(_amountController.text) ?? 0,
    );

    final Map<String, int> splits = {};
    if (_splitType == SplitType.equal) {
      if (_selectedMemberIds.isNotEmpty) {
        final equalSplits = MoneyUtils.splitEqual(
          totalAmountMinor,
          _selectedMemberIds.length,
        );
        final sortedIds = _selectedMemberIds.toList()..sort();
        for (int i = 0; i < sortedIds.length; i++) {
          splits[sortedIds[i]] = equalSplits[i];
        }
      }
    } else {
      for (var id in _selectedMemberIds) {
        final text = _customAmountControllers[id]?.text ?? '0';
        splits[id] = MoneyUtils.toMinorUnits(double.tryParse(text) ?? 0);
      }
    }

    final memberNames = {for (var m in members) m.id: m.displayName};

    return SplitPreviewBar(
      totalAmount: totalAmountMinor,
      splits: splits,
      memberNames: memberNames,
      currencyCode: currency,
    );
  }
}
