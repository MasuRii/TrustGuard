import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../../settings/providers/lock_providers.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ExportScreen({super.key, required this.groupId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;

  Future<void> _handleExportCsv(String groupName) async {
    final lockState = ref.read(appLockStateProvider);

    if (lockState.requireUnlockToExport) {
      final verified = await _verifyIdentity();
      if (!verified) return;
    }

    setState(() => _isExporting = true);
    try {
      await ref.read(exportServiceProvider).shareCsv(widget.groupId, groupName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShareSummary(String groupName) async {
    final lockState = ref.read(appLockStateProvider);

    if (lockState.requireUnlockToExport) {
      final verified = await _verifyIdentity();
      if (!verified) return;
    }

    setState(() => _isExporting = true);
    try {
      await ref
          .read(exportServiceProvider)
          .shareTextSummary(widget.groupId, groupName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sharing failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<bool> _verifyIdentity() async {
    final lockState = ref.read(appLockStateProvider);
    if (!lockState.hasPin) return true;

    // Try biometrics first if enabled
    if (lockState.isBiometricEnabled) {
      final success = await ref
          .read(appLockStateProvider.notifier)
          .authenticateBiometrically();
      if (success) return true;
    }

    // Fallback to PIN dialog
    if (!mounted) return false;
    final pin = await _showPinDialog();
    if (pin == null) return false;

    return ref.read(appLockStateProvider.notifier).unlock(pin);
  }

  Future<String?> _showPinDialog() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify PIN'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'Enter 4-digit PIN'),
          onChanged: (value) => pin = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pin),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final transactionsAsync = ref.watch(
      transactionsByGroupProvider(widget.groupId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Export Group Data')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.import_export, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Export data for ${group.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        transactionsAsync.when<Widget>(
                          data: (txs) => Text(
                            '${txs.length} transactions will be exported.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          loading: () => const Text('Counting transactions...'),
                          error: (_, __) =>
                              const Text('Error counting transactions'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select an export format below to share or save your data.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExportCsv(group.name),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _handleShareSummary(group.name),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Text Summary'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (_isExporting) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                const Spacer(),
                const Text(
                  'CSV exports include full transaction history, while text summaries provide a quick overview of balances and suggested settlements.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
