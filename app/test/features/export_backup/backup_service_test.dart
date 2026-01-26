import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/database/repositories/tag_repository.dart';
import 'package:trustguard/src/core/database/repositories/reminder_repository.dart';
import 'package:trustguard/src/features/export_backup/services/backup_service.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/tag.dart';
import 'package:trustguard/src/core/models/reminder_settings.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockTagRepository extends Mock implements TagRepository {}

class MockReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late BackupService backupService;
  late MockGroupRepository mockGroupRepository;
  late MockMemberRepository mockMemberRepository;
  late MockTransactionRepository mockTransactionRepository;
  late MockTagRepository mockTagRepository;
  late MockReminderRepository mockReminderRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockMemberRepository = MockMemberRepository();
    mockTransactionRepository = MockTransactionRepository();
    mockTagRepository = MockTagRepository();
    mockReminderRepository = MockReminderRepository();

    backupService = BackupService(
      groupRepository: mockGroupRepository,
      memberRepository: mockMemberRepository,
      transactionRepository: mockTransactionRepository,
      tagRepository: mockTagRepository,
      reminderRepository: mockReminderRepository,
    );
  });

  test('createBackup returns a complete backup object', () async {
    // Arrange
    final now = DateTime(2026, 1, 26, 12, 0);
    final group = Group(
      id: 'g1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: now,
    );
    final member = Member(
      id: 'm1',
      groupId: 'g1',
      displayName: 'Member 1',
      createdAt: now,
    );
    final transaction = Transaction(
      id: 't1',
      groupId: 'g1',
      type: TransactionType.expense,
      occurredAt: now,
      note: 'Test Tx',
      createdAt: now,
      updatedAt: now,
    );
    final tag = const Tag(id: 'tag1', groupId: 'g1', name: 'Tag 1');
    final reminder = const ReminderSettings(
      groupId: 'g1',
      enabled: true,
      schedule: ReminderSchedule.daily,
    );

    when(
      () => mockGroupRepository.getAllGroups(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => [group]);
    when(
      () => mockMemberRepository.getAllMembers(),
    ).thenAnswer((_) async => [member]);
    when(
      () => mockTransactionRepository.getAllTransactions(),
    ).thenAnswer((_) async => [transaction]);
    when(() => mockTagRepository.getAllTags()).thenAnswer((_) async => [tag]);
    when(
      () => mockReminderRepository.getAllReminderSettings(),
    ).thenAnswer((_) async => [reminder]);

    // Act
    final backup = await backupService.createBackup();

    // Assert
    expect(backup.schemaVersion, 1);
    expect(backup.groups, [group]);
    expect(backup.members, [member]);
    expect(backup.transactions, [transaction]);
    expect(backup.tags, [tag]);
    expect(backup.reminderSettings, [reminder]);

    // Test serialization roundtrip
    final jsonString = jsonEncode(backup.toJson());
    final decodedJson = jsonDecode(jsonString);
    expect(decodedJson['schemaVersion'], 1);
    expect(decodedJson['groups'], isA<List<dynamic>>());
    expect((decodedJson['groups'] as List<dynamic>).first['id'], 'g1');
  });
}
