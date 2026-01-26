import '../database.dart';
import '../../models/reminder_settings.dart';
import '../mappers/reminder_mapper.dart';

abstract class ReminderRepository {
  Future<List<ReminderSettings>> getAllReminderSettings();
  Future<ReminderSettings?> getReminderSettings(String groupId);
  Stream<ReminderSettings?> watchReminderSettings(String groupId);
  Future<void> upsertReminderSettings(ReminderSettings settings);
}

class DriftReminderRepository implements ReminderRepository {
  final AppDatabase _db;

  DriftReminderRepository(this._db);

  @override
  Future<List<ReminderSettings>> getAllReminderSettings() async {
    final rows = await _db.select(_db.groupReminders).get();
    return rows.map(ReminderMapper.toModel).toList();
  }

  @override
  Future<ReminderSettings?> getReminderSettings(String groupId) async {
    final query = _db.select(_db.groupReminders)
      ..where((t) => t.groupId.equals(groupId));
    final row = await query.getSingleOrNull();
    return row != null ? ReminderMapper.toModel(row) : null;
  }

  @override
  Stream<ReminderSettings?> watchReminderSettings(String groupId) {
    final query = _db.select(_db.groupReminders)
      ..where((t) => t.groupId.equals(groupId));
    return query.watchSingleOrNull().map(
      (row) => row != null ? ReminderMapper.toModel(row) : null,
    );
  }

  @override
  Future<void> upsertReminderSettings(ReminderSettings settings) async {
    await _db
        .into(_db.groupReminders)
        .insertOnConflictUpdate(ReminderMapper.toCompanion(settings));
  }
}
