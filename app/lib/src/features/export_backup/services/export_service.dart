import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../balances/services/balance_service.dart';
import '../../balances/services/settlement_service.dart';
import '../../settings/services/settings_service.dart';

/// Service for generating and sharing export files (CSV, Text Summary).
class ExportService {
  final TransactionRepository _transactionRepository;
  final MemberRepository _memberRepository;
  final SettingsService _settingsService;

  ExportService({
    required TransactionRepository transactionRepository,
    required MemberRepository memberRepository,
    required SettingsService settingsService,
  }) : _transactionRepository = transactionRepository,
       _memberRepository = memberRepository,
       _settingsService = settingsService;

  /// Generates a CSV string containing all transactions for a group.
  Future<String> generateCsv(String groupId) async {
    final transactions = await _transactionRepository.getTransactionsByGroup(
      groupId,
    );
    final members = await _memberRepository.getMembersByGroup(
      groupId,
      includeRemoved: true,
    );
    final memberNames = {for (var m in members) m.id: m.displayName};

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    final List<String> csvRows = [];

    // Header
    csvRows.add(
      'Date,Type,Amount,Payer/From,Participants/To,Note,Tags,Original Amount,Original Currency,Exchange Rate',
    );

    final decimalDigits = _settingsService.getRoundingDecimalPlaces();

    for (final tx in transactions) {
      final date = formatter.format(tx.occurredAt);
      final type = tx.type.name;
      final note = '"${tx.note.replaceAll('"', '""')}"';
      final tags =
          '"${tx.tags.map((t) => t.name).join(', ').replaceAll('"', '""')}"';

      String amount = '';
      String from = '';
      String to = '';
      String originalAmount = '';
      String originalCurrency = '';
      String exchangeRate = '';

      if (tx.type == TransactionType.expense && tx.expenseDetail != null) {
        amount = MoneyUtils.fromMinorUnits(
          tx.expenseDetail!.totalAmountMinor,
        ).toStringAsFixed(decimalDigits);
        from = memberNames[tx.expenseDetail!.payerMemberId] ?? 'Unknown';
        to =
            '"${tx.expenseDetail!.participants.map((p) => memberNames[p.memberId] ?? 'Unknown').join(', ').replaceAll('"', '""')}"';

        if (tx.expenseDetail!.exchangeRate != null) {
          originalAmount = MoneyUtils.fromMinorUnits(
            tx.expenseDetail!.originalAmountMinor ?? 0,
          ).toStringAsFixed(decimalDigits);
          originalCurrency = tx.expenseDetail!.originalCurrencyCode ?? '';
          exchangeRate = tx.expenseDetail!.exchangeRate!.toString();
        }
      } else if (tx.type == TransactionType.transfer &&
          tx.transferDetail != null) {
        amount = MoneyUtils.fromMinorUnits(
          tx.transferDetail!.amountMinor,
        ).toStringAsFixed(decimalDigits);
        from = memberNames[tx.transferDetail!.fromMemberId] ?? 'Unknown';
        to = memberNames[tx.transferDetail!.toMemberId] ?? 'Unknown';
      }

      csvRows.add(
        '$date,$type,$amount,$from,$to,$note,$tags,$originalAmount,$originalCurrency,$exchangeRate',
      );
    }

    return csvRows.join('\n');
  }

  /// Generates a human-readable text summary of the group state.
  Future<String> generateTextSummary(String groupId, String groupName) async {
    final members = await _memberRepository.getMembersByGroup(
      groupId,
      includeRemoved: true,
    );
    final transactions = await _transactionRepository.getTransactionsByGroup(
      groupId,
    );

    final memberIds = members.map((m) => m.id).toList();
    final memberNames = {for (var m in members) m.id: m.displayName};

    final balances = BalanceService.computeBalances(
      memberIds: memberIds,
      memberNames: memberNames,
      transactions: transactions,
    );
    final suggestions = SettlementService.computeSettlementSuggestions(
      balances,
    );

    final decimalDigits = _settingsService.getRoundingDecimalPlaces();

    final buffer = StringBuffer();
    buffer.writeln('TrustGuard Summary: $groupName');
    buffer.writeln(
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );

    final hasMultiCurrency = transactions.any(
      (tx) => tx.expenseDetail?.exchangeRate != null,
    );
    if (hasMultiCurrency) {
      buffer.writeln(
        'Note: Some expenses were converted using manual exchange rates.',
      );
    }
    buffer.writeln();

    buffer.writeln('--- BALANCES ---');
    if (balances.isEmpty) {
      buffer.writeln('No members found.');
    } else {
      for (final b in balances) {
        final amount = MoneyUtils.fromMinorUnits(
          b.netAmountMinor.abs(),
        ).toStringAsFixed(decimalDigits);
        if (b.netAmountMinor > 0) {
          buffer.writeln('${b.memberName}: Owed $amount');
        } else if (b.netAmountMinor < 0) {
          buffer.writeln('${b.memberName}: Owes $amount');
        } else {
          buffer.writeln('${b.memberName}: Settled');
        }
      }
    }
    buffer.writeln();

    buffer.writeln('--- SUGGESTED SETTLEMENTS ---');
    if (suggestions.isEmpty) {
      buffer.writeln('All settled! No transfers needed.');
    } else {
      for (final s in suggestions) {
        final amount = MoneyUtils.fromMinorUnits(
          s.amountMinor,
        ).toStringAsFixed(decimalDigits);
        buffer.writeln('${s.fromMemberName} -> ${s.toMemberName}: $amount');
      }
    }

    buffer.writeln();
    buffer.writeln('Shared via TrustGuard (Offline-First Expense Tracking)');

    return buffer.toString();
  }

  /// Exports and shares the group data as a CSV file.
  Future<void> shareCsv(String groupId, String groupName) async {
    final csvContent = await generateCsv(groupId);
    final directory = await getTemporaryDirectory();
    final safeGroupName = groupName.replaceAll(RegExp(r'[^\w\s-]'), '');
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'TrustGuard_${safeGroupName}_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvContent, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'TrustGuard Export - $groupName',
      ),
    );
  }

  /// Shares the text summary via the platform share sheet.
  Future<void> shareTextSummary(String groupId, String groupName) async {
    final summary = await generateTextSummary(groupId, groupName);
    await SharePlus.instance.share(
      ShareParams(text: summary, subject: 'TrustGuard Summary - $groupName'),
    );
  }
}
