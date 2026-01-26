// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TrustGuard';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get newGroup => 'New Group';

  @override
  String get createGroup => 'Create Group';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noArchivedGroups => 'No archived groups';

  @override
  String get noGroupsMessage =>
      'Create a group to start tracking expenses and settlements with your friends.';

  @override
  String get noArchivedGroupsMessage => 'Archived groups will appear here.';

  @override
  String get showArchived => 'Show Archived';

  @override
  String get hideArchived => 'Hide Archived';

  @override
  String membersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get balance => 'Balance';

  @override
  String get settled => 'Settled';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get groupOptions => 'Group options';

  @override
  String errorLoadingGroups(String error) {
    return 'Error loading groups: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get filterTransactions => 'Filter Transactions';

  @override
  String get searchNote => 'Search note...';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get noTransactionsMessage =>
      'Add your first expense or transfer to get started.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters.';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String tagFilter(String name) {
    return 'Tag: $name';
  }

  @override
  String memberFilter(String name) {
    return 'Member: $name';
  }

  @override
  String afterFilter(String date) {
    return 'After: $date';
  }

  @override
  String beforeFilter(String date) {
    return 'Before: $date';
  }

  @override
  String get addExpense => 'Add Expense';

  @override
  String get addTransfer => 'Add Transfer';

  @override
  String get noNote => 'No note';

  @override
  String paidByFor(String payer, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return 'Paid by $payer for $_temp0';
  }

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get display => 'Display';

  @override
  String get rounding => 'Rounding';

  @override
  String decimalPlaces(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decimal places',
      one: '1 decimal place',
    );
    return '$_temp0';
  }

  @override
  String get security => 'Security';

  @override
  String get setPin => 'Set PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get pinActive => 'PIN is active';

  @override
  String get pinNotSet => 'PIN is not set';

  @override
  String get biometricUnlock => 'Biometric Unlock';

  @override
  String get biometricUnlockDesc => 'Use fingerprint or face ID';

  @override
  String get lockOnBackground => 'Lock on Background';

  @override
  String get lockOnBackgroundDesc => 'Lock app when minimized';

  @override
  String get exportProtection => 'Export Protection';

  @override
  String get exportProtectionDesc => 'Require unlock to export data';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableReminders => 'Enable Reminders';

  @override
  String get remindersDesc => 'Get notified about unsettled balances';

  @override
  String get data => 'Data';

  @override
  String get attachmentStorage => 'Attachment Storage';

  @override
  String mbUsed(String size) {
    return '$size MB used';
  }

  @override
  String get calculating => 'Calculating...';

  @override
  String get clearOrphaned => 'Clear Orphaned';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get helpPrivacy => 'Help & Privacy';

  @override
  String get helpPrivacyDesc => 'User guide and privacy policy';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get developer => 'Developer';

  @override
  String get debugLogs => 'Debug Logs';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get dashboardTitle => 'Your Overview';

  @override
  String get youOwe => 'You Owe';

  @override
  String get owedToYou => 'Owed to You';

  @override
  String get netBalance => 'Net';

  @override
  String groupsSummary(num groupCount, num unsettledCount) {
    String _temp0 = intl.Intl.pluralLogic(
      groupCount,
      locale: localeName,
      other: 'groups',
      one: 'group',
    );
    String _temp1 = intl.Intl.pluralLogic(
      unsettledCount,
      locale: localeName,
      other: '$unsettledCount need settling',
      one: '1 needs settling',
      zero: 'all settled',
    );
    return '$groupCount $_temp0, $_temp1';
  }
}
