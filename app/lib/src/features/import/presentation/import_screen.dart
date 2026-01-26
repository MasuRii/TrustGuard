import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/utils/haptics.dart';
import '../../../generated/app_localizations.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import '../models/import_result.dart';
import '../services/csv_import_service.dart';
import '../providers/import_providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ImportScreen({super.key, required this.groupId});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _csvContent;
  String? _fileName;
  CsvFormat _detectedFormat = CsvFormat.unknown;
  List<List<dynamic>> _previewRows = [];
  List<String> _csvMemberNames = [];
  final Map<String, String?> _memberMapping = {};
  bool _isImporting = false;
  ImportResult? _importResult;

  static const String _createNewId = 'CREATE_NEW';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final importService = ref.read(csvImportServiceProvider);

      final format = importService.detectCsvFormat(content);
      final names = await importService.getMemberNamesFromCsv(content);

      final rows = const CsvToListConverter().convert(content);

      setState(() {
        _csvContent = content;
        _fileName = result.files.single.name;
        _detectedFormat = format;
        _csvMemberNames = names;
        _previewRows = rows.take(6).toList(); // Header + 5 rows
        _importResult = null;

        _memberMapping.clear();
        for (final name in names) {
          _memberMapping[name] = null;
        }
      });
    }
  }

  Future<void> _handleImport() async {
    if (_csvContent == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final memberRepo = ref.read(memberRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);
      final importService = ref.read(csvImportServiceProvider);

      // 1. Create new members if needed
      final finalMapping = <String, String>{};
      for (final entry in _memberMapping.entries) {
        if (entry.value == _createNewId) {
          final newMember = Member(
            id: const Uuid().v4(),
            groupId: widget.groupId,
            displayName: entry.key,
            createdAt: DateTime.now(),
          );
          await memberRepo.createMember(newMember);
          finalMapping[entry.key] = newMember.id;
        } else if (entry.value != null) {
          finalMapping[entry.key] = entry.value!;
        }
      }

      // 2. Perform import
      final result = await importService.importCsv(
        _csvContent!,
        widget.groupId,
        memberMapping: finalMapping,
      );

      // 3. Save transactions
      if (result.transactions.isNotEmpty) {
        for (final tx in result.transactions) {
          await txRepo.createTransaction(tx);
        }
      }

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      if (mounted) {
        HapticsService.success();
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  bool get _isMappingComplete {
    if (_csvMemberNames.isEmpty) {
      return _csvContent != null && _detectedFormat != CsvFormat.unknown;
    }
    return _memberMapping.values.every((v) => v != null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importData)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: AppTheme.space24),

            if (_fileName == null)
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: Text(l10n.selectCsvFile),
              )
            else ...[
              _buildFileSummary(l10n),
              const SizedBox(height: AppTheme.space24),
              _buildPreviewTable(context),
              const SizedBox(height: AppTheme.space24),
              membersAsync.when(
                data: (members) => _buildMemberMapping(l10n, members),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading members: $e'),
              ),
              const SizedBox(height: AppTheme.space32),
              if (_importResult == null)
                ElevatedButton(
                  onPressed: (_isMappingComplete && !_isImporting)
                      ? _handleImport
                      : null,
                  child: _isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.importData),
                )
              else
                _buildImportResult(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.blue),
            SizedBox(height: AppTheme.space16),
            Text(
              'Import expenses from other apps. Supported formats: Splitwise (CSV), Tricount (CSV).',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.space8),
            Text(
              'Make sure your CSV file includes column headers for best results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSummary(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: Colors.green),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                _fileName ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              onPressed: _pickFile,
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Change File',
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          l10n.detectedFormat(_detectedFormat.name.toUpperCase()),
          style: TextStyle(
            color: _detectedFormat == CsvFormat.unknown
                ? Colors.red
                : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTable(BuildContext context) {
    if (_previewRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview (First 5 Rows)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.space8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 40,
              columns: _previewRows.first
                  .map(
                    (col) => DataColumn(
                      label: Text(
                        col.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: _previewRows
                  .skip(1)
                  .map(
                    (row) => DataRow(
                      cells: row
                          .map(
                            (cell) => DataCell(
                              Text(
                                cell.toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberMapping(
    AppLocalizations l10n,
    List<Member> existingMembers,
  ) {
    if (_csvMemberNames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mapMembers,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: AppTheme.space8),
        const Text(
          'Connect people from your CSV to members in this group.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: AppTheme.space16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _csvMemberNames.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final csvName = _csvMemberNames[index];
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    csvName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text(
                      'Select Member',
                      style: TextStyle(fontSize: 12),
                    ),
                    initialValue: _memberMapping[csvName],
                    items: [
                      ...existingMembers.map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            m.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: _createNewId,
                        child: Text(
                          '+ Create New Member',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _memberMapping[csvName] = value;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildImportResult(AppLocalizations l10n) {
    final result = _importResult!;
    return Card(
      color: result.failedCount == 0
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  result.failedCount == 0 ? Icons.check_circle : Icons.warning,
                  color: result.failedCount == 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.importSuccess(result.successCount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (result.failedCount > 0)
                        Text(
                          l10n.importErrors(result.failedCount),
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.errors.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Errors details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: AppTheme.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  itemBuilder: (context, index) {
                    final err = result.errors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Row ${err.rowNumber}: ${err.message}',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Group'),
            ),
          ],
        ),
      ),
    );
  }
}
