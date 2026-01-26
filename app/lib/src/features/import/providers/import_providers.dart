import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/csv_import_service.dart';

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  return CsvImportService();
});
