import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/providers.dart';
import '../../../core/platform/local_log_service.dart';
import '../../../ui/theme/app_theme.dart';

final debugLogsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final service = ref.watch(localLogServiceProvider);
  return service.readLogs();
});

class DebugLogsScreen extends ConsumerWidget {
  const DebugLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logService = ref.watch(localLogServiceProvider);
    final logsAsync = ref.watch(debugLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final file = await logService.exportLogs();
              if (file != null) {
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    subject: 'TrustGuard Debug Logs',
                  ),
                );
              }
            },
            tooltip: 'Export Logs',
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearLogsDialog(context, ref),
            tooltip: 'Clear Logs',
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No logs found'));
          }

          // Reverse to show newest first
          final reversedLogs = logs.reversed.toList();

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space8),
            itemCount: reversedLogs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              try {
                final entry = LogEntry.fromJson(reversedLogs[index]);
                return _LogEntryTile(entry: entry);
              } catch (e) {
                return ListTile(
                  title: Text(reversedLogs[index]),
                  subtitle: const Text('Malformed log entry'),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _showClearLogsDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('This will permanently delete all debug logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(localLogServiceProvider).clearLogs();
      ref.invalidate(debugLogsProvider);
    }
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final Color levelColor;
    switch (entry.level) {
      case LogLevel.fatal:
      case LogLevel.error:
        levelColor = Colors.red;
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        break;
      case LogLevel.debug:
        levelColor = Colors.grey;
        break;
    }

    return ListTile(
      dense: true,
      title: Text(
        '[${entry.level.name.toUpperCase()}] ${entry.message}',
        style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.timestamp.toString(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (entry.context != null)
            Text(
              'Context: ${entry.context}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (entry.stackTrace != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.stackTrace!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      onTap: () => _showLogDetail(context),
    );
  }

  void _showLogDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.level.name.toUpperCase()),
        content: SingleChildScrollView(
          child: SelectableText(
            'Time: ${entry.timestamp}\n\n'
            'Message: ${entry.message}\n\n'
            'Context: ${entry.context}\n\n'
            'Stack Trace:\n${entry.stackTrace ?? "None"}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
