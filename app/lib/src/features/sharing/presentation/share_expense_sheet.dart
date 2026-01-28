import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/utils/money.dart';
import 'package:trustguard/src/features/sharing/models/shareable_expense.dart';
import 'package:trustguard/src/features/sharing/services/qr_generation_service.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';

class ShareExpenseSheet extends ConsumerStatefulWidget {
  final Transaction transaction;

  const ShareExpenseSheet({super.key, required this.transaction});

  @override
  ConsumerState<ShareExpenseSheet> createState() => _ShareExpenseSheetState();
}

class _ShareExpenseSheetState extends ConsumerState<ShareExpenseSheet> {
  String? _qrData;
  ShareableExpense? _generatedExpense;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  Future<void> _generateQr() async {
    try {
      final service = ref.read(qrGenerationServiceProvider);
      final expense = await service.generateForTransaction(widget.transaction);
      final data = service.getQrData(expense);
      if (mounted) {
        setState(() {
          _generatedExpense = expense;
          _qrData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate QR code: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareText() async {
    if (_qrData == null || _generatedExpense == null) return;

    final expense = _generatedExpense!;
    final amount = MoneyUtils.format(
      expense.amountMinor,
      currencyCode: expense.currencyCode,
    );

    final text =
        'TrustGuard Expense: ${expense.description} - $amount\n\nCode: $_qrData';

    // ignore: deprecated_member_use
    await Share.share(text, subject: 'Shared Expense');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.space16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Share Expense',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Container(
                          height: 250,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (_qrData != null)
                        Column(
                          children: [
                            Container(
                              width: 280,
                              height: 280,
                              padding: const EdgeInsets.all(AppTheme.space16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: QrImageView(
                                  data: _qrData!,
                                  version: QrVersions.auto,
                                  size: 250,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Colors.black,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Colors.black,
                                  ),
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),

                            // Expense Summary
                            _buildSummary(theme),

                            const SizedBox(height: AppTheme.space24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  'Scan with TrustGuard app',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space16),

              if (!_isLoading && _error == null)
                FilledButton.icon(
                  onPressed: _shareText,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Code as Text'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(ThemeData theme) {
    if (_generatedExpense == null) return const SizedBox.shrink();

    final expense = _generatedExpense!;

    return Column(
      children: [
        Text(
          expense.description,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          MoneyUtils.format(
            expense.amountMinor,
            currencyCode: expense.currencyCode,
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
