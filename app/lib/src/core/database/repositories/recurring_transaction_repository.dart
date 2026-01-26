import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/recurring_transaction_mapper.dart';
import '../../models/recurring_transaction.dart' as model;

abstract class RecurringTransactionRepository {
  Future<void> createRecurring(model.RecurringTransaction recurring);
  Future<List<model.RecurringTransaction>> getActiveRecurringsForGroup(
    String groupId,
  );
  Future<List<model.RecurringTransaction>> getDueRecurrings(DateTime now);
  Future<void> updateNextOccurrence(String id, DateTime next);
  Future<void> deactivateRecurring(String id);
  Future<model.RecurringTransaction?> getRecurringByTemplateId(
    String templateId,
  );
}

class DriftRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final AppDatabase _db;

  DriftRecurringTransactionRepository(this._db);

  @override
  Future<void> createRecurring(model.RecurringTransaction recurring) async {
    await _db
        .into(_db.recurringTransactions)
        .insert(RecurringTransactionMapper.toCompanion(recurring));
  }

  @override
  Future<List<model.RecurringTransaction>> getActiveRecurringsForGroup(
    String groupId,
  ) async {
    final query = _db.select(_db.recurringTransactions)
      ..where((t) => t.groupId.equals(groupId) & t.isActive.equals(true));
    final rows = await query.get();
    return rows.map(RecurringTransactionMapper.toModel).toList();
  }

  @override
  Future<List<model.RecurringTransaction>> getDueRecurrings(
    DateTime now,
  ) async {
    final query = _db.select(_db.recurringTransactions)
      ..where(
        (t) =>
            t.isActive.equals(true) &
            t.nextOccurrence.isSmallerOrEqualValue(now),
      );
    final rows = await query.get();
    return rows.map(RecurringTransactionMapper.toModel).toList();
  }

  @override
  Future<void> updateNextOccurrence(String id, DateTime next) async {
    await (_db.update(_db.recurringTransactions)..where((t) => t.id.equals(id)))
        .write(RecurringTransactionsCompanion(nextOccurrence: Value(next)));
  }

  @override
  Future<void> deactivateRecurring(String id) async {
    await (_db.update(_db.recurringTransactions)..where((t) => t.id.equals(id)))
        .write(const RecurringTransactionsCompanion(isActive: Value(false)));
  }

  @override
  Future<model.RecurringTransaction?> getRecurringByTemplateId(
    String templateId,
  ) async {
    final query = _db.select(_db.recurringTransactions)
      ..where((t) => t.templateTransactionId.equals(templateId));
    final row = await query.getSingleOrNull();
    return row != null ? RecurringTransactionMapper.toModel(row) : null;
  }
}
