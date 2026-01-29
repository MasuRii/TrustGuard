import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum LogLevel { debug, info, warning, error, fatal }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.stackTrace,
    this.context,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'stackTrace': stackTrace,
    'context': context,
  };

  @override
  String toString() => jsonEncode(toJson());

  factory LogEntry.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;
    return LogEntry(
      timestamp: DateTime.parse(data['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (e) => e.name == data['level'] as String,
      ),
      message: data['message'] as String,
      stackTrace: data['stackTrace'] as String?,
      context: data['context'] as Map<String, dynamic>?,
    );
  }
}

class LocalLogService {
  static final LocalLogService _instance = LocalLogService._internal();
  factory LocalLogService() => _instance;
  LocalLogService._internal();

  static const String _logFileName = 'trustguard_logs.txt';
  static const String _oldLogFileName = 'trustguard_logs.txt.old';
  static const int _maxFileSize = 1024 * 1024; // 1MB

  File? _logFile;

  /// Whether file-based logging is supported on the current platform.
  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (!isSupported) return;

    final directory = await getApplicationDocumentsDirectory();
    _logFile = File(p.join(directory.path, _logFileName));
  }

  Future<void> _checkRotation() async {
    if (_logFile == null) await init();
    if (await _logFile!.exists()) {
      final size = await _logFile!.length();
      if (size > _maxFileSize) {
        final oldFile = File(p.join(_logFile!.parent.path, _oldLogFileName));
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
        await _logFile!.rename(oldFile.path);
      }
    }
  }

  Future<void> writeLog(LogEntry entry) async {
    // On web, just print to console
    if (!isSupported) {
      debugPrint('[${entry.level.name.toUpperCase()}] ${entry.message}');
      return;
    }

    try {
      await _checkRotation();
      await _logFile!.writeAsString(
        '${entry.toString()}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // Fallback to print if file logging fails
      // ignore: avoid_print
      debugPrint('Failed to write log: $e');
    }
  }

  Future<void> debug(String message, {Map<String, dynamic>? context}) =>
      writeLog(
        LogEntry(
          timestamp: DateTime.now(),
          level: LogLevel.debug,
          message: message,
          context: context,
        ),
      );

  Future<void> info(String message, {Map<String, dynamic>? context}) =>
      writeLog(
        LogEntry(
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: message,
          context: context,
        ),
      );

  Future<void> warning(String message, {Map<String, dynamic>? context}) =>
      writeLog(
        LogEntry(
          timestamp: DateTime.now(),
          level: LogLevel.warning,
          message: message,
          context: context,
        ),
      );

  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) => writeLog(
    LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      message: error != null ? '$message: $error' : message,
      stackTrace: stackTrace?.toString(),
      context: context,
    ),
  );

  Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) => writeLog(
    LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.fatal,
      message: error != null ? '$message: $error' : message,
      stackTrace: stackTrace?.toString(),
      context: context,
    ),
  );

  Future<List<String>> readLogs() async {
    if (!isSupported) return [];

    if (_logFile == null) await init();
    if (!await _logFile!.exists()) return [];

    final lines = await _logFile!.readAsLines();
    if (lines.length > 500) {
      return lines.sublist(lines.length - 500);
    }
    return lines;
  }

  Future<void> clearLogs() async {
    if (!isSupported) return;

    if (_logFile == null) await init();
    if (await _logFile!.exists()) {
      await _logFile!.delete();
    }
    final oldFile = File(p.join(_logFile!.parent.path, _oldLogFileName));
    if (await oldFile.exists()) {
      await oldFile.delete();
    }
  }

  Future<File?> exportLogs() async {
    if (!isSupported) return null;

    if (_logFile == null) await init();
    if (await _logFile!.exists()) {
      return _logFile;
    }
    return null;
  }
}
