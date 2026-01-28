import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/budget_mapper.dart';
import '../../models/budget.dart' as model;

abstract class BudgetRepository {
  Future<List<model.Budget>> getBudgetsByGroup(String groupId);
  Stream<List<model.Budget>> watchBudgetsByGroup(String groupId);
  Stream<List<model.Budget>> watchActiveBudgets(String groupId);
  Future<model.Budget?> getBudgetForTag(String groupId, String tagId);
  Future<model.Budget?> getBudgetById(String id);
  Future<void> createBudget(model.Budget budget);
  Future<void> updateBudget(model.Budget budget);
  Future<void> deleteBudget(String id);
  Future<void> toggleActive(String id, bool isActive);
}

class DriftBudgetRepository implements BudgetRepository {
  final AppDatabase _db;

  DriftBudgetRepository(this._db);

  @override
  Future<List<model.Budget>> getBudgetsByGroup(String groupId) async {
    final query = _db.select(_db.budgets)
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map((row) => row.toModel()).toList();
  }

  @override
  Stream<List<model.Budget>> watchBudgetsByGroup(String groupId) {
    final query = _db.select(_db.budgets)
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => rows.map((row) => row.toModel()).toList(),
    );
  }

  @override
  Stream<List<model.Budget>> watchActiveBudgets(String groupId) {
    final query = _db.select(_db.budgets)
      ..where((t) => t.groupId.equals(groupId))
      ..where((t) => t.isActive.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
      (rows) => rows.map((row) => row.toModel()).toList(),
    );
  }

  @override
  Future<model.Budget?> getBudgetForTag(String groupId, String tagId) async {
    final query = _db.select(_db.budgets)
      ..where((t) => t.groupId.equals(groupId))
      ..where((t) => t.tagId.equals(tagId))
      ..where((t) => t.isActive.equals(true));

    final row = await query.getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<model.Budget?> getBudgetById(String id) async {
    final query = _db.select(_db.budgets)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> createBudget(model.Budget budget) async {
    await _db.into(_db.budgets).insert(budget.toCompanion());
  }

  @override
  Future<void> updateBudget(model.Budget budget) async {
    await (_db.update(
      _db.budgets,
    )..where((t) => t.id.equals(budget.id))).write(budget.toCompanion());
  }

  @override
  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(isActive: Value(isActive)),
    );
  }
}
