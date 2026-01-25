import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/models/group.dart' as model;

void main() {
  late AppDatabase db;
  late GroupRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftGroupRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('GroupRepository', () {
    final testGroup = model.Group(
      id: 'group-1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime(2026, 1, 1),
    );

    test('createGroup and getGroupById', () async {
      await repository.createGroup(testGroup);
      final group = await repository.getGroupById('group-1');
      expect(group, equals(testGroup));
    });

    test('getAllGroups and watchGroups', () async {
      await repository.createGroup(testGroup);

      final allGroups = await repository.getAllGroups();
      expect(allGroups, hasLength(1));
      expect(allGroups.first, equals(testGroup));

      final groupsStream = repository.watchGroups();
      expect(groupsStream, emits(contains(testGroup)));
    });

    test('updateGroup', () async {
      await repository.createGroup(testGroup);
      final updatedGroup = testGroup.copyWith(name: 'Updated Name');

      await repository.updateGroup(updatedGroup);
      final group = await repository.getGroupById('group-1');
      expect(group?.name, equals('Updated Name'));
    });

    test('archive and unarchive group', () async {
      await repository.createGroup(testGroup);

      await repository.archiveGroup('group-1');
      var group = await repository.getGroupById('group-1');
      expect(group?.archivedAt, isNotNull);

      final activeGroups = await repository.getAllGroups(
        includeArchived: false,
      );
      expect(activeGroups, isEmpty);

      final allGroups = await repository.getAllGroups(includeArchived: true);
      expect(allGroups, hasLength(1));

      await repository.unarchiveGroup('group-1');
      group = await repository.getGroupById('group-1');
      expect(group?.archivedAt, isNull);

      final activeGroupsAfter = await repository.getAllGroups(
        includeArchived: false,
      );
      expect(activeGroupsAfter, hasLength(1));
    });
  });
}
