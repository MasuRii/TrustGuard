import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/attachment.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import '../services/attachment_service.dart';
import 'transactions_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String groupId;
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.groupId,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionProvider(transactionId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final membersAsync = ref.watch(membersByGroupProvider(groupId));
    final attachmentsAsync = ref.watch(attachmentsProvider(transactionId));
    final formatMoney = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          transactionAsync.when(
            data: (tx) => tx != null
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      if (tx.type == TransactionType.expense) {
                        context.push(
                          '/group/$groupId/transactions/add-expense?txId=$transactionId',
                        );
                      } else {
                        context.push(
                          '/group/$groupId/transactions/add-transfer?txId=$transactionId',
                        );
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text('Transaction not found'));
          }

          return groupAsync.when(
            data: (group) {
              final currency = group?.currencyCode ?? 'USD';
              return membersAsync.when(
                data: (members) {
                  final memberMap = {
                    for (var m in members) m.id: m.displayName,
                  };
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, tx, currency, formatMoney),
                        const Divider(height: AppTheme.space32),
                        _buildInfoSection(context, tx, memberMap),
                        if (tx.expenseDetail?.exchangeRate != null) ...[
                          const SizedBox(height: AppTheme.space12),
                          _buildInfoRow(
                            context,
                            Icons.currency_exchange_outlined,
                            'Original Amount',
                            '${formatMoney(tx.expenseDetail!.originalAmountMinor ?? 0, currencyCode: tx.expenseDetail!.originalCurrencyCode ?? 'USD')} (Rate: ${tx.expenseDetail!.exchangeRate!.toStringAsFixed(4)})',
                          ),
                        ],
                        const SizedBox(height: AppTheme.space24),
                        if (tx.type == TransactionType.expense)
                          _buildSplitSection(
                            context,
                            tx,
                            memberMap,
                            currency,
                            formatMoney,
                          ),
                        if (tx.tags.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space24),
                          _buildTagsSection(context, tx),
                        ],
                        const SizedBox(height: AppTheme.space24),
                        _buildAttachmentsSection(
                          context,
                          ref,
                          transactionId,
                          attachmentsAsync,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading members: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading group: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Transaction tx,
    String currency,
    MoneyFormatter formatMoney,
  ) {
    final amount = tx.type == TransactionType.expense
        ? tx.expenseDetail?.totalAmountMinor ?? 0
        : tx.transferDetail?.amountMinor ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              tx.type == TransactionType.expense
                  ? Icons.shopping_cart_outlined
                  : Icons.swap_horiz,
              color: tx.type == TransactionType.expense
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.space8),
            Text(
              tx.type == TransactionType.expense ? 'Expense' : 'Transfer',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tx.type == TransactionType.expense
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          formatMoney(amount, currencyCode: currency),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (tx.note.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space8),
          Text(tx.note, style: Theme.of(context).textTheme.titleLarge),
        ],
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    Transaction tx,
    Map<String, String> memberMap,
  ) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          Icons.calendar_today_outlined,
          'Date',
          DateFormat.yMMMMd().add_jm().format(tx.occurredAt),
        ),
        const SizedBox(height: AppTheme.space12),
        if (tx.type == TransactionType.expense)
          _buildInfoRow(
            context,
            Icons.person_outline,
            'Paid by',
            memberMap[tx.expenseDetail?.payerMemberId] ?? 'Unknown Member',
          ),
        if (tx.type == TransactionType.transfer) ...[
          _buildInfoRow(
            context,
            Icons.person_outline,
            'From',
            memberMap[tx.transferDetail?.fromMemberId] ?? 'Unknown Member',
          ),
          const SizedBox(height: AppTheme.space12),
          _buildInfoRow(
            context,
            Icons.person_outline,
            'To',
            memberMap[tx.transferDetail?.toMemberId] ?? 'Unknown Member',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).hintColor),
        const SizedBox(width: AppTheme.space12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildSplitSection(
    BuildContext context,
    Transaction tx,
    Map<String, String> memberMap,
    String currency,
    MoneyFormatter formatMoney,
  ) {
    final participants = tx.expenseDetail?.participants ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = participants[index];
              return ListTile(
                title: Text(memberMap[p.memberId] ?? 'Unknown Member'),
                trailing: Text(
                  formatMoney(p.owedAmountMinor, currencyCode: currency),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, Transaction tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tx.tags.map((tag) {
            return Chip(
              label: Text(tag.name),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(
    BuildContext context,
    WidgetRef ref,
    String txId,
    AsyncValue<List<Attachment>> attachmentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              onPressed: () => _addAttachment(context, ref, txId),
              tooltip: 'Add Photo',
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return Text(
                'No attachments yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  return _AttachmentThumbnail(
                    attachment: attachment,
                    onDelete: () =>
                        _confirmDeleteAttachment(context, ref, attachment),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading attachments: $e'),
        ),
      ],
    );
  }

  Future<void> _addAttachment(
    BuildContext context,
    WidgetRef ref,
    String txId,
  ) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source);
    if (image == null) return;

    try {
      final savedPath = await AttachmentService().saveAttachment(
        txId,
        File(image.path),
      );
      await ref
          .read(attachmentRepositoryProvider)
          .createAttachment(txId, savedPath, image.mimeType ?? 'image/jpeg');
      ref.invalidate(attachmentsProvider(txId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attachment: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAttachment(
    BuildContext context,
    WidgetRef ref,
    Attachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment?'),
        content: const Text('This will permanently delete this photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AttachmentService().deleteAttachment(attachment.path);
      await ref
          .read(attachmentRepositoryProvider)
          .deleteAttachment(attachment.id);
      ref.invalidate(attachmentsProvider(attachment.txId));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'This will remove the transaction from balances and history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.softDeleteTransaction(transactionId);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () =>
                  repository.undoSoftDeleteTransaction(transactionId),
            ),
          ),
        );
      }
    }
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onDelete;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _viewFullImage(context),
        onLongPress: onDelete,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(attachment.path),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.zoom_in, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(child: Image.file(File(attachment.path))),
          ),
        ),
      ),
    );
  }
}
