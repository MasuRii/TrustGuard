import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'TrustGuard'**
  String get appTitle;

  /// Title for the transactions screen
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// Title for the groups screen
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No description provided for @noArchivedGroups.
  ///
  /// In en, this message translates to:
  /// **'No archived groups'**
  String get noArchivedGroups;

  /// No description provided for @noGroupsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a group to start tracking expenses and settlements with your friends.'**
  String get noGroupsMessage;

  /// No description provided for @noArchivedGroupsMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived groups will appear here.'**
  String get noArchivedGroupsMessage;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get showArchived;

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide Archived'**
  String get hideArchived;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(num count);

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @groupOptions.
  ///
  /// In en, this message translates to:
  /// **'Group options'**
  String get groupOptions;

  /// No description provided for @errorLoadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Error loading groups: {error}'**
  String errorLoadingGroups(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @searchNote.
  ///
  /// In en, this message translates to:
  /// **'Search note...'**
  String get searchNote;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense or transfer to get started.'**
  String get noTransactionsMessage;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters.'**
  String get tryAdjustingFilters;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @tagFilter.
  ///
  /// In en, this message translates to:
  /// **'Tag: {name}'**
  String tagFilter(String name);

  /// No description provided for @memberFilter.
  ///
  /// In en, this message translates to:
  /// **'Member: {name}'**
  String memberFilter(String name);

  /// No description provided for @afterFilter.
  ///
  /// In en, this message translates to:
  /// **'After: {date}'**
  String afterFilter(String date);

  /// No description provided for @beforeFilter.
  ///
  /// In en, this message translates to:
  /// **'Before: {date}'**
  String beforeFilter(String date);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addTransfer.
  ///
  /// In en, this message translates to:
  /// **'Add Transfer'**
  String get addTransfer;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// No description provided for @paidByFor.
  ///
  /// In en, this message translates to:
  /// **'Paid by {payer} for {count, plural, =1{1 member} other{{count} members}}'**
  String paidByFor(String payer, num count);

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @rounding.
  ///
  /// In en, this message translates to:
  /// **'Rounding'**
  String get rounding;

  /// No description provided for @decimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 decimal place} other{{count} decimal places}}'**
  String decimalPlaces(num count);

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @pinActive.
  ///
  /// In en, this message translates to:
  /// **'PIN is active'**
  String get pinActive;

  /// No description provided for @pinNotSet.
  ///
  /// In en, this message translates to:
  /// **'PIN is not set'**
  String get pinNotSet;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricUnlock;

  /// No description provided for @biometricUnlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID'**
  String get biometricUnlockDesc;

  /// No description provided for @lockOnBackground.
  ///
  /// In en, this message translates to:
  /// **'Lock on Background'**
  String get lockOnBackground;

  /// No description provided for @lockOnBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Lock app when minimized'**
  String get lockOnBackgroundDesc;

  /// No description provided for @exportProtection.
  ///
  /// In en, this message translates to:
  /// **'Export Protection'**
  String get exportProtection;

  /// No description provided for @exportProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Require unlock to export data'**
  String get exportProtectionDesc;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableReminders;

  /// No description provided for @remindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about unsettled balances'**
  String get remindersDesc;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @attachmentStorage.
  ///
  /// In en, this message translates to:
  /// **'Attachment Storage'**
  String get attachmentStorage;

  /// No description provided for @mbUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} MB used'**
  String mbUsed(String size);

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @clearOrphaned.
  ///
  /// In en, this message translates to:
  /// **'Clear Orphaned'**
  String get clearOrphaned;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @helpPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Help & Privacy'**
  String get helpPrivacy;

  /// No description provided for @helpPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'User guide and privacy policy'**
  String get helpPrivacyDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @debugLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get debugLogs;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Overview'**
  String get dashboardTitle;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You Owe'**
  String get youOwe;

  /// No description provided for @owedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to You'**
  String get owedToYou;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netBalance;

  /// No description provided for @groupsSummary.
  ///
  /// In en, this message translates to:
  /// **'{groupCount} {groupCount, plural, =1{group} other{groups}}, {unsettledCount, plural, =0{all settled} =1{1 needs settling} other{{unsettledCount} need settling}}'**
  String groupsSummary(num groupCount, num unsettledCount);

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @timeAgo.
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String timeAgo(String time);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get selectNone;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @splitBetween.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get splitBetween;

  /// No description provided for @splitEqually.
  ///
  /// In en, this message translates to:
  /// **'Split Equally'**
  String get splitEqually;

  /// No description provided for @splitCustomly.
  ///
  /// In en, this message translates to:
  /// **'Split Customly'**
  String get splitCustomly;

  /// No description provided for @swipeToEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get swipeToEdit;

  /// No description provided for @swipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get swipeToDelete;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteTransactionConfirm;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @actionUndone.
  ///
  /// In en, this message translates to:
  /// **'Action undone'**
  String get actionUndone;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incoming;

  /// No description provided for @otherSettlements.
  ///
  /// In en, this message translates to:
  /// **'Other Settlements'**
  String get otherSettlements;

  /// No description provided for @allSettledUp.
  ///
  /// In en, this message translates to:
  /// **'All settled up!'**
  String get allSettledUp;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @totalMatches.
  ///
  /// In en, this message translates to:
  /// **'Total matches!'**
  String get totalMatches;

  /// No description provided for @totalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Total mismatch'**
  String get totalMismatch;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get over;

  /// No description provided for @splitPortion.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount} ({percent}%)'**
  String splitPortion(String name, String amount, String percent);

  /// No description provided for @whichOneIsYou.
  ///
  /// In en, this message translates to:
  /// **'Which one is you?'**
  String get whichOneIsYou;

  /// No description provided for @selectSelfMember.
  ///
  /// In en, this message translates to:
  /// **'Tap a member to see what you owe or are owed.'**
  String get selectSelfMember;

  /// No description provided for @owesLabel.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get owesLabel;

  /// No description provided for @isOwedLabel.
  ///
  /// In en, this message translates to:
  /// **'is owed'**
  String get isOwedLabel;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @spendingByMember.
  ///
  /// In en, this message translates to:
  /// **'Who Spent Most'**
  String get spendingByMember;

  /// No description provided for @monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend'**
  String get monthlyTrend;

  /// No description provided for @period3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get period3Months;

  /// No description provided for @period6Months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get period6Months;

  /// No description provided for @period12Months.
  ///
  /// In en, this message translates to:
  /// **'12 Months'**
  String get period12Months;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @ocrConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get ocrConfidenceHigh;

  /// No description provided for @ocrConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence - please verify'**
  String get ocrConfidenceMedium;

  /// No description provided for @ocrConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low confidence - please verify'**
  String get ocrConfidenceLow;

  /// No description provided for @applyScannedData.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyScannedData;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get biweekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @repeatUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get repeatUntil;

  /// No description provided for @repeatForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get repeatForever;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @selectCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Select CSV File'**
  String get selectCsvFile;

  /// No description provided for @detectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Detected Format: {format}'**
  String detectedFormat(String format);

  /// No description provided for @mapMembers.
  ///
  /// In en, this message translates to:
  /// **'Map Members'**
  String get mapMembers;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} transactions'**
  String importSuccess(num count);

  /// No description provided for @importErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} rows could not be imported'**
  String importErrors(num count);

  /// No description provided for @useCustomKeypad.
  ///
  /// In en, this message translates to:
  /// **'Use calculator-style input'**
  String get useCustomKeypad;

  /// No description provided for @useCustomKeypadDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a specialized keypad for amount entry'**
  String get useCustomKeypadDesc;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Equal split with all members'**
  String get quickAddHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @groupArchived.
  ///
  /// In en, this message translates to:
  /// **'Group archived'**
  String get groupArchived;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @noGroupsImportMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to create a group before you can import data.'**
  String get noGroupsImportMessage;

  /// No description provided for @swipeActionHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to edit or delete transactions'**
  String get swipeActionHint;

  /// No description provided for @receiptScanHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan a receipt and auto-fill the amount'**
  String get receiptScanHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
