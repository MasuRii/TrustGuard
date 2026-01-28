import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/member.dart';
import '../services/qr_scanner_service.dart';
import '../models/shareable_expense.dart';
import '../../groups/presentation/groups_providers.dart';

class ScanExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ScanExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<ScanExpenseScreen> createState() => _ScanExpenseScreenState();
}

class _ScanExpenseScreenState extends ConsumerState<ScanExpenseScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final service = ref.read(qrScannerServiceProvider);
      final data = service.parseQrData(rawValue);

      if (data is ShareableExpense) {
        await _handleScannedExpense(data);
      } else if (data is ShareableBatch) {
        // TODO: Handle batch import
        _showError('Batch import is not supported yet.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleScannedExpense(ShareableExpense expense) async {
    // Pause scanner during dialog
    await _controller.stop();

    if (!mounted) return;

    final members = await ref.read(
      membersByGroupProvider(widget.groupId).future,
    );

    if (!mounted) return;

    // Show preview and mapping dialog
    final shouldImport = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExpenseImportDialog(
        expense: expense,
        existingMembers: members,
        groupId: widget.groupId,
      ),
    );

    if (shouldImport == true) {
      if (mounted) {
        context.pop(); // Go back to previous screen
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense imported successfully')),
          );
        }
      }
    } else {
      // Resume scanner if cancelled
      if (mounted) {
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Expense'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Overlay guide
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Hint text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseImportDialog extends ConsumerStatefulWidget {
  final ShareableExpense expense;
  final List<Member> existingMembers;
  final String groupId;

  const _ExpenseImportDialog({
    required this.expense,
    required this.existingMembers,
    required this.groupId,
  });

  @override
  ConsumerState<_ExpenseImportDialog> createState() =>
      _ExpenseImportDialogState();
}

class _ExpenseImportDialogState extends ConsumerState<_ExpenseImportDialog> {
  late Map<String, String?>
  _memberMapping; // External Name -> Local Member ID (null = create new)
  late List<String> _unknownNames;

  @override
  void initState() {
    super.initState();
    _memberMapping = {};
    _unknownNames = [];
    _initializeMapping();
  }

  void _initializeMapping() {
    final namesToMap = {
      widget.expense.payerName,
      ...widget.expense.participants.map((p) => p.name),
    };

    for (final name in namesToMap) {
      final match = widget.existingMembers.cast<Member?>().firstWhere(
        (m) => m!.displayName.toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );

      if (match != null) {
        _memberMapping[name] = match.id;
      } else {
        _memberMapping[name] = null; // Default to create new
        _unknownNames.add(name);
      }
    }
  }

  Future<void> _import() async {
    try {
      // 1. Create missing members
      final nameToIdMap = Map<String, String>.from(_memberMapping);
      final memberRepo = ref.read(memberRepositoryProvider);

      for (final name in _unknownNames) {
        if (_memberMapping[name] == null) {
          // Create new member
          final newMember = Member(
            id: const Uuid().v4(),
            groupId: widget.groupId,
            displayName: name,
            createdAt: DateTime.now(),
          );
          await memberRepo.createMember(newMember);
          nameToIdMap[name] = newMember.id;
        } else {
          // Used existing mapping
          nameToIdMap[name] = _memberMapping[name]!;
        }
      }

      // 2. Create Transaction
      final txRepo = ref.read(transactionRepositoryProvider);
      final payerId = nameToIdMap[widget.expense.payerName]!;

      final mappedParticipants = widget.expense.participants.map((p) {
        final memberId = nameToIdMap[p.name]!;
        return ExpenseParticipant(
          memberId: memberId,
          owedAmountMinor: p.amountMinor,
        );
      }).toList();

      final transaction = Transaction(
        id: const Uuid()
            .v4(), // or use widget.expense.sourceId if we want to track source
        groupId: widget.groupId,
        type: TransactionType.expense,
        occurredAt: widget.expense.date,
        note: widget.expense.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expenseDetail: ExpenseDetail(
          payerMemberId: payerId,
          totalAmountMinor: widget.expense.amountMinor,
          splitType: SplitType.custom,
          participants: mappedParticipants,
          originalCurrencyCode: widget.expense.currencyCode,
        ),
      );

      await txRepo.createTransaction(transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.expense.currencyCode;
    final formatter = ref.watch(moneyFormatterProvider);

    return AlertDialog(
      title: const Text('Import Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.expense.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              formatter(widget.expense.amountMinor, currencyCode: currency),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            if (_unknownNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Map Members',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Some names do not match current group members. Please match them or create new members.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ..._unknownNames.map((name) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _memberMapping[name],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Create New'),
                            ),
                            ...widget.existingMembers.map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.displayName),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _memberMapping[name] = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const Text('All members matched!'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _import, child: const Text('Import')),
      ],
    );
  }
}
