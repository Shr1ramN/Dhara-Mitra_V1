import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
  ];

  /// No description provided for @aWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dhara Mitra'**
  String get aWelcome;

  /// No description provided for @aGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get aGoogle;

  /// No description provided for @aEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get aEmail;

  /// No description provided for @aLocal.
  ///
  /// In en, this message translates to:
  /// **'Continue locally'**
  String get aLocal;

  /// No description provided for @aLocalMode.
  ///
  /// In en, this message translates to:
  /// **'Local mode'**
  String get aLocalMode;

  /// No description provided for @aAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get aAccount;

  /// No description provided for @aSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get aSignOut;

  /// No description provided for @aChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose how to use Dhara Mitra'**
  String get aChooseMode;

  /// No description provided for @aLocalWarning.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this device. If you uninstall the app, clear its data, or lose your phone, your records cannot be recovered unless you have manually saved a backup outside the app.'**
  String get aLocalWarning;

  /// No description provided for @aAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand that I must save backups manually.'**
  String get aAcknowledge;

  /// No description provided for @aManualBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is not available yet. Signing in does not back up your records. Save manual backups outside the app.'**
  String get aManualBackup;

  /// No description provided for @aSeparateRecords.
  ///
  /// In en, this message translates to:
  /// **'Accounts have separate farm records on this device. Your existing local farms stay in local mode. To move them, export an all-farm backup in local mode, then import it after signing in.'**
  String get aSeparateRecords;

  /// No description provided for @aNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is not configured in this build. You can continue locally and save manual backups.'**
  String get aNotConfigured;

  /// No description provided for @aUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is temporarily unavailable. Try again later or continue locally.'**
  String get aUnavailable;

  /// No description provided for @aEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get aEmailAddress;

  /// No description provided for @aPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get aPassword;

  /// No description provided for @aConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get aConfirmPassword;

  /// No description provided for @aSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get aSignIn;

  /// No description provided for @aCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get aCreateAccount;

  /// No description provided for @aForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get aForgotPassword;

  /// No description provided for @aSendReset.
  ///
  /// In en, this message translates to:
  /// **'Send password reset email'**
  String get aSendReset;

  /// No description provided for @aResetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a password reset link has been sent. Open it on this device.'**
  String get aResetSent;

  /// No description provided for @aVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in. Open the confirmation link on this device.'**
  String get aVerifyEmail;

  /// No description provided for @aNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get aNewPassword;

  /// No description provided for @aSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get aSavePassword;

  /// No description provided for @aInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get aInvalidEmail;

  /// No description provided for @aPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get aPasswordRequired;

  /// No description provided for @aPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get aPasswordLength;

  /// No description provided for @aPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get aPasswordMismatch;

  /// No description provided for @aAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your details and email confirmation, or try again when online.'**
  String get aAuthFailed;

  /// No description provided for @aRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this request. Check your connection and try again.'**
  String get aRequestFailed;

  /// No description provided for @aBrowserOpened.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in in your browser. If you cancelled, you can try again or continue locally.'**
  String get aBrowserOpened;

  /// No description provided for @aLeaveLocal.
  ///
  /// In en, this message translates to:
  /// **'Choose a sign-in method'**
  String get aLeaveLocal;

  /// No description provided for @aSignOutInfo.
  ///
  /// In en, this message translates to:
  /// **'Your records will stay on this device. Sign back in to this account to access them. Cloud backup is not available yet.'**
  String get aSignOutInfo;

  /// No description provided for @aBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get aBackupRestore;

  /// No description provided for @aRestoreLocal.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup in local mode'**
  String get aRestoreLocal;

  /// No description provided for @aShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get aShowPassword;

  /// No description provided for @aHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get aHidePassword;

  /// No description provided for @aBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get aBack;

  /// No description provided for @aCancelRecovery.
  ///
  /// In en, this message translates to:
  /// **'Cancel and sign out'**
  String get aCancelRecovery;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dhara Mitra'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHarvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get navHarvest;

  /// No description provided for @navLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get navLabour;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get invalidNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @lakhUnit.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lakhUnit;

  /// No description provided for @kgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// No description provided for @kgValue.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String kgValue(String kg);

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get confirmDelete;

  /// No description provided for @deleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the app.'**
  String get deleteCannotUndo;

  /// No description provided for @cropAreca.
  ///
  /// In en, this message translates to:
  /// **'Arecanut'**
  String get cropAreca;

  /// No description provided for @cropCoconut.
  ///
  /// In en, this message translates to:
  /// **'Coconut'**
  String get cropCoconut;

  /// No description provided for @cropPepper.
  ///
  /// In en, this message translates to:
  /// **'Pepper'**
  String get cropPepper;

  /// No description provided for @cropBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get cropBanana;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm'**
  String get setupTitle;

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved on this phone and works without internet. You can change all of this later under More.'**
  String get setupIntro;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmName;

  /// No description provided for @farmNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bhat Thota'**
  String get farmNameHint;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @villageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kemminje, Puttur'**
  String get villageHint;

  /// No description provided for @seasonStarts.
  ///
  /// In en, this message translates to:
  /// **'Season starts in'**
  String get seasonStarts;

  /// No description provided for @plotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get plotsTitle;

  /// No description provided for @setupPlotsHint.
  ///
  /// In en, this message translates to:
  /// **'Add each part of the garden you look after separately, like Upper plot and Lower plot.'**
  String get setupPlotsHint;

  /// No description provided for @addPlot.
  ///
  /// In en, this message translates to:
  /// **'Add plot'**
  String get addPlot;

  /// No description provided for @editPlot.
  ///
  /// In en, this message translates to:
  /// **'Edit plot'**
  String get editPlot;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'Start using Dhara Mitra'**
  String get startUsing;

  /// No description provided for @needOnePlot.
  ///
  /// In en, this message translates to:
  /// **'Add at least one plot'**
  String get needOnePlot;

  /// No description provided for @plotName.
  ///
  /// In en, this message translates to:
  /// **'Plot name'**
  String get plotName;

  /// No description provided for @plotNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Upper plot'**
  String get plotNameHint;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acres;

  /// No description provided for @acresGuntas.
  ///
  /// In en, this message translates to:
  /// **'{acres} acres {guntas} guntas'**
  String acresGuntas(int acres, int guntas);

  /// No description provided for @soil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soil;

  /// No description provided for @soilHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Laterite'**
  String get soilHint;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @irrSprinkler.
  ///
  /// In en, this message translates to:
  /// **'Sprinklers'**
  String get irrSprinkler;

  /// No description provided for @irrDrip.
  ///
  /// In en, this message translates to:
  /// **'Drip'**
  String get irrDrip;

  /// No description provided for @irrHose.
  ///
  /// In en, this message translates to:
  /// **'Hose'**
  String get irrHose;

  /// No description provided for @irrNone.
  ///
  /// In en, this message translates to:
  /// **'Rain-fed'**
  String get irrNone;

  /// No description provided for @arecaPalms.
  ///
  /// In en, this message translates to:
  /// **'Areca palms'**
  String get arecaPalms;

  /// No description provided for @coconutTrees.
  ///
  /// In en, this message translates to:
  /// **'Coconut trees'**
  String get coconutTrees;

  /// No description provided for @pepperVines.
  ///
  /// In en, this message translates to:
  /// **'Pepper vines'**
  String get pepperVines;

  /// No description provided for @bananaClumps.
  ///
  /// In en, this message translates to:
  /// **'Banana plants'**
  String get bananaClumps;

  /// No description provided for @palmsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} palms'**
  String palmsCount(int n);

  /// No description provided for @deletePlot.
  ///
  /// In en, this message translates to:
  /// **'Delete plot'**
  String get deletePlot;

  /// No description provided for @namaskara.
  ///
  /// In en, this message translates to:
  /// **'Namaskara'**
  String get namaskara;

  /// No description provided for @dryingNow.
  ///
  /// In en, this message translates to:
  /// **'Drying now'**
  String get dryingNow;

  /// No description provided for @inStorage.
  ///
  /// In en, this message translates to:
  /// **'In storage'**
  String get inStorage;

  /// No description provided for @waitingForYou.
  ///
  /// In en, this message translates to:
  /// **'Next step waiting'**
  String get waitingForYou;

  /// No description provided for @dayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of ~{target}'**
  String dayOf(int day, int target);

  /// No description provided for @expectedDone.
  ///
  /// In en, this message translates to:
  /// **'Expected done {date}'**
  String expectedDone(String date);

  /// No description provided for @logRainCover.
  ///
  /// In en, this message translates to:
  /// **'Log rain cover'**
  String get logRainCover;

  /// No description provided for @coverLogged.
  ///
  /// In en, this message translates to:
  /// **'Rain cover logged'**
  String get coverLogged;

  /// No description provided for @qaHarvest.
  ///
  /// In en, this message translates to:
  /// **'New harvest'**
  String get qaHarvest;

  /// No description provided for @qaAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get qaAttendance;

  /// No description provided for @qaPay.
  ///
  /// In en, this message translates to:
  /// **'Pay worker'**
  String get qaPay;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @toPayWorkers.
  ///
  /// In en, this message translates to:
  /// **'To pay workers'**
  String get toPayWorkers;

  /// No description provided for @toReceive.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get toReceive;

  /// No description provided for @daysInStore.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day in store} other{{n} days in store}}'**
  String daysInStore(int n);

  /// No description provided for @kgLeft.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg left'**
  String kgLeft(String kg);

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start by recording a harvest. The app counts the drying days, peeling cost and profit for you.'**
  String get homeEmpty;

  /// No description provided for @lotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Harvest lots'**
  String get lotsTitle;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get filterSold;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @newHarvest.
  ///
  /// In en, this message translates to:
  /// **'New harvest'**
  String get newHarvest;

  /// No description provided for @noLots.
  ///
  /// In en, this message translates to:
  /// **'No lots here yet. Tap New harvest when the climbers finish a round.'**
  String get noLots;

  /// No description provided for @stageHarvest.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get stageHarvest;

  /// No description provided for @stageDrying.
  ///
  /// In en, this message translates to:
  /// **'Drying'**
  String get stageDrying;

  /// No description provided for @stagePeeling.
  ///
  /// In en, this message translates to:
  /// **'Peeling'**
  String get stagePeeling;

  /// No description provided for @stageGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get stageGrading;

  /// No description provided for @stageStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get stageStorage;

  /// No description provided for @stageSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get stageSold;

  /// No description provided for @seasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String seasonLabel(String season);

  /// No description provided for @harvestTitle.
  ///
  /// In en, this message translates to:
  /// **'New harvest'**
  String get harvestTitle;

  /// No description provided for @lotTitle.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lotTitle;

  /// No description provided for @lotTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Harvest round 1 · Upper plot'**
  String get lotTitleHint;

  /// No description provided for @harvestRound.
  ///
  /// In en, this message translates to:
  /// **'Harvest round {n}'**
  String harvestRound(int n);

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest date'**
  String get harvestDate;

  /// No description provided for @whichPlots.
  ///
  /// In en, this message translates to:
  /// **'Which plots?'**
  String get whichPlots;

  /// No description provided for @palmsClimbed.
  ///
  /// In en, this message translates to:
  /// **'Palms climbed'**
  String get palmsClimbed;

  /// No description provided for @freshKg.
  ///
  /// In en, this message translates to:
  /// **'Fresh nuts (kg)'**
  String get freshKg;

  /// No description provided for @labourSection.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labourSection;

  /// No description provided for @addLabourLine.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get addLabourLine;

  /// No description provided for @noLabour.
  ///
  /// In en, this message translates to:
  /// **'No labour added'**
  String get noLabour;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @chooseWorker.
  ///
  /// In en, this message translates to:
  /// **'Choose worker'**
  String get chooseWorker;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @rateRupees.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹)'**
  String get rateRupees;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get unitDay;

  /// No description provided for @unitPalm.
  ///
  /// In en, this message translates to:
  /// **'palm'**
  String get unitPalm;

  /// No description provided for @unitTree.
  ///
  /// In en, this message translates to:
  /// **'tree'**
  String get unitTree;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitNut.
  ///
  /// In en, this message translates to:
  /// **'nut'**
  String get unitNut;

  /// No description provided for @unitLump.
  ///
  /// In en, this message translates to:
  /// **'lump sum'**
  String get unitLump;

  /// No description provided for @labourCost.
  ///
  /// In en, this message translates to:
  /// **'Labour cost'**
  String get labourCost;

  /// No description provided for @noWorkersYet.
  ///
  /// In en, this message translates to:
  /// **'Add workers under Labour first.'**
  String get noWorkersYet;

  /// No description provided for @secHarvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get secHarvest;

  /// No description provided for @secDrying.
  ///
  /// In en, this message translates to:
  /// **'Drying'**
  String get secDrying;

  /// No description provided for @secPeeling.
  ///
  /// In en, this message translates to:
  /// **'Peeling'**
  String get secPeeling;

  /// No description provided for @secGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get secGrading;

  /// No description provided for @secStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get secStorage;

  /// No description provided for @secSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get secSales;

  /// No description provided for @secMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get secMoney;

  /// No description provided for @secLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get secLog;

  /// No description provided for @plots.
  ///
  /// In en, this message translates to:
  /// **'Plots'**
  String get plots;

  /// No description provided for @startDrying.
  ///
  /// In en, this message translates to:
  /// **'Start drying'**
  String get startDrying;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @daysOnYard.
  ///
  /// In en, this message translates to:
  /// **'Days on the yard'**
  String get daysOnYard;

  /// No description provided for @yard.
  ///
  /// In en, this message translates to:
  /// **'Yard'**
  String get yard;

  /// No description provided for @yardHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main yard · tarpaulin'**
  String get yardHint;

  /// No description provided for @targetDays.
  ///
  /// In en, this message translates to:
  /// **'Expected drying days'**
  String get targetDays;

  /// No description provided for @coveredForRain.
  ///
  /// In en, this message translates to:
  /// **'Covered for rain'**
  String get coveredForRain;

  /// No description provided for @turned.
  ///
  /// In en, this message translates to:
  /// **'Turned'**
  String get turned;

  /// No description provided for @nTimes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{not yet} =1{once} other{{n} times}}'**
  String nTimes(int n);

  /// No description provided for @logTurning.
  ///
  /// In en, this message translates to:
  /// **'Log turning'**
  String get logTurning;

  /// No description provided for @turningLogged.
  ///
  /// In en, this message translates to:
  /// **'Turning logged'**
  String get turningLogged;

  /// No description provided for @finishDrying.
  ///
  /// In en, this message translates to:
  /// **'Drying finished'**
  String get finishDrying;

  /// No description provided for @driedKg.
  ///
  /// In en, this message translates to:
  /// **'Dried nuts in husk (kg)'**
  String get driedKg;

  /// No description provided for @recordPeeling.
  ///
  /// In en, this message translates to:
  /// **'Record peeling'**
  String get recordPeeling;

  /// No description provided for @chaliKg.
  ///
  /// In en, this message translates to:
  /// **'Chali after peeling (kg)'**
  String get chaliKg;

  /// No description provided for @outTurn.
  ///
  /// In en, this message translates to:
  /// **'Out-turn'**
  String get outTurn;

  /// No description provided for @peelers.
  ///
  /// In en, this message translates to:
  /// **'Peelers'**
  String get peelers;

  /// No description provided for @peelingCost.
  ///
  /// In en, this message translates to:
  /// **'Total peeling cost'**
  String get peelingCost;

  /// No description provided for @enterGrades.
  ///
  /// In en, this message translates to:
  /// **'Enter grades'**
  String get enterGrades;

  /// No description provided for @editGrades.
  ///
  /// In en, this message translates to:
  /// **'Edit grades'**
  String get editGrades;

  /// No description provided for @gradeChali.
  ///
  /// In en, this message translates to:
  /// **'Chali'**
  String get gradeChali;

  /// No description provided for @gradePatora.
  ///
  /// In en, this message translates to:
  /// **'Patora'**
  String get gradePatora;

  /// No description provided for @gradeUlliGadde.
  ///
  /// In en, this message translates to:
  /// **'Ulli gadde'**
  String get gradeUlliGadde;

  /// No description provided for @gradeKarigotu.
  ///
  /// In en, this message translates to:
  /// **'Karigotu'**
  String get gradeKarigotu;

  /// No description provided for @gradeKoka.
  ///
  /// In en, this message translates to:
  /// **'Koka'**
  String get gradeKoka;

  /// No description provided for @gradedTotal.
  ///
  /// In en, this message translates to:
  /// **'Graded total'**
  String get gradedTotal;

  /// No description provided for @skipGrading.
  ///
  /// In en, this message translates to:
  /// **'Sold or stored without grading? Go straight to storage or sale.'**
  String get skipGrading;

  /// No description provided for @moveToStorage.
  ///
  /// In en, this message translates to:
  /// **'Move to storage'**
  String get moveToStorage;

  /// No description provided for @storagePlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get storagePlace;

  /// No description provided for @storagePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Attic store room'**
  String get storagePlaceHint;

  /// No description provided for @bags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get bags;

  /// No description provided for @storedSince.
  ///
  /// In en, this message translates to:
  /// **'Stored since'**
  String get storedSince;

  /// No description provided for @daysInStorage.
  ///
  /// In en, this message translates to:
  /// **'Days in storage'**
  String get daysInStorage;

  /// No description provided for @priceWhenStored.
  ///
  /// In en, this message translates to:
  /// **'Price when stored (₹/kg)'**
  String get priceWhenStored;

  /// No description provided for @valueAtStoredPrice.
  ///
  /// In en, this message translates to:
  /// **'Value of what\'s left at the stored price'**
  String get valueAtStoredPrice;

  /// No description provided for @logCheck.
  ///
  /// In en, this message translates to:
  /// **'Log check'**
  String get logCheck;

  /// No description provided for @checkKind.
  ///
  /// In en, this message translates to:
  /// **'What was checked?'**
  String get checkKind;

  /// No description provided for @checkValue.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get checkValue;

  /// No description provided for @checkValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 11% or no weevils'**
  String get checkValueHint;

  /// No description provided for @recordSale.
  ///
  /// In en, this message translates to:
  /// **'Record sale'**
  String get recordSale;

  /// No description provided for @soldSoFar.
  ///
  /// In en, this message translates to:
  /// **'Sold so far'**
  String get soldSoFar;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'Nothing sold yet'**
  String get noSales;

  /// No description provided for @notStartedYet.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get notStartedYet;

  /// No description provided for @saleTitle.
  ///
  /// In en, this message translates to:
  /// **'Record sale'**
  String get saleTitle;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @chooseBuyer.
  ///
  /// In en, this message translates to:
  /// **'Choose buyer'**
  String get chooseBuyer;

  /// No description provided for @newBuyer.
  ///
  /// In en, this message translates to:
  /// **'New buyer'**
  String get newBuyer;

  /// No description provided for @buyerName.
  ///
  /// In en, this message translates to:
  /// **'Buyer name'**
  String get buyerName;

  /// No description provided for @buyerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CAMPCO · Puttur branch'**
  String get buyerNameHint;

  /// No description provided for @buyerCampco.
  ///
  /// In en, this message translates to:
  /// **'CAMPCO'**
  String get buyerCampco;

  /// No description provided for @buyerTrader.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get buyerTrader;

  /// No description provided for @buyerApmc.
  ///
  /// In en, this message translates to:
  /// **'APMC agent'**
  String get buyerApmc;

  /// No description provided for @buyerOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get buyerOther;

  /// No description provided for @whatWasSold.
  ///
  /// In en, this message translates to:
  /// **'What was sold'**
  String get whatWasSold;

  /// No description provided for @ratePerKg.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹/kg)'**
  String get ratePerKg;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get gross;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions (₹)'**
  String get deductions;

  /// No description provided for @deductionsHint.
  ///
  /// In en, this message translates to:
  /// **'Moisture cut, commission, hamali, transport'**
  String get deductionsHint;

  /// No description provided for @deductionNote.
  ///
  /// In en, this message translates to:
  /// **'What were the deductions?'**
  String get deductionNote;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @receivedNow.
  ///
  /// In en, this message translates to:
  /// **'Received now (₹)'**
  String get receivedNow;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get fullyPaid;

  /// No description provided for @updateReceived.
  ///
  /// In en, this message translates to:
  /// **'Update received'**
  String get updateReceived;

  /// No description provided for @moreThanLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {kg} kg left'**
  String moreThanLeft(String kg);

  /// No description provided for @enterSomethingSold.
  ///
  /// In en, this message translates to:
  /// **'Enter the kg sold for at least one grade'**
  String get enterSomethingSold;

  /// No description provided for @deleteSale.
  ///
  /// In en, this message translates to:
  /// **'Delete sale'**
  String get deleteSale;

  /// No description provided for @lotCost.
  ///
  /// In en, this message translates to:
  /// **'Harvest + processing cost'**
  String get lotCost;

  /// No description provided for @saleValue.
  ///
  /// In en, this message translates to:
  /// **'Sale value'**
  String get saleValue;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @costPerKg.
  ///
  /// In en, this message translates to:
  /// **'Cost per kg of chali'**
  String get costPerKg;

  /// No description provided for @deleteLot.
  ///
  /// In en, this message translates to:
  /// **'Delete lot'**
  String get deleteLot;

  /// No description provided for @deleteLotBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes this lot with its labour, grades and sales. Workers\' accounts are corrected.'**
  String get deleteLotBody;

  /// No description provided for @eventCover.
  ///
  /// In en, this message translates to:
  /// **'Covered for rain'**
  String get eventCover;

  /// No description provided for @eventTurn.
  ///
  /// In en, this message translates to:
  /// **'Turned'**
  String get eventTurn;

  /// No description provided for @eventMoisture.
  ///
  /// In en, this message translates to:
  /// **'Moisture check'**
  String get eventMoisture;

  /// No description provided for @eventPest.
  ///
  /// In en, this message translates to:
  /// **'Pest check'**
  String get eventPest;

  /// No description provided for @eventNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get eventNote;

  /// No description provided for @removeLabourLine.
  ///
  /// In en, this message translates to:
  /// **'Remove this labour entry? It is also removed from the worker\'s account.'**
  String get removeLabourLine;

  /// No description provided for @labourTitle.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labourTitle;

  /// No description provided for @tabWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get tabWorkers;

  /// No description provided for @tabAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get tabAttendance;

  /// No description provided for @tabDues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get tabDues;

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get addWorker;

  /// No description provided for @noWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers yet. Add the people who work in your garden.'**
  String get noWorkers;

  /// No description provided for @roleClimber.
  ///
  /// In en, this message translates to:
  /// **'Climber'**
  String get roleClimber;

  /// No description provided for @roleSprayer.
  ///
  /// In en, this message translates to:
  /// **'Sprayer'**
  String get roleSprayer;

  /// No description provided for @rolePeeler.
  ///
  /// In en, this message translates to:
  /// **'Areca peeler'**
  String get rolePeeler;

  /// No description provided for @roleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily labour'**
  String get roleDaily;

  /// No description provided for @rolePlucker.
  ///
  /// In en, this message translates to:
  /// **'Coconut plucker'**
  String get rolePlucker;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @advanceHeld.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount}'**
  String advanceHeld(String amount);

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'No longer working'**
  String get inactive;

  /// No description provided for @presentCount.
  ///
  /// In en, this message translates to:
  /// **'{n} present'**
  String presentCount(int n);

  /// No description provided for @wages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get wages;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save attendance'**
  String get saveAttendance;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @half.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get half;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @workToday.
  ///
  /// In en, this message translates to:
  /// **'Work done'**
  String get workToday;

  /// No description provided for @workHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fertiliser · Upper plot'**
  String get workHint;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get attendanceSaved;

  /// No description provided for @noDayRate.
  ///
  /// In en, this message translates to:
  /// **'No day rate set'**
  String get noDayRate;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due to workers'**
  String get totalDue;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @nobodyDue.
  ///
  /// In en, this message translates to:
  /// **'Nobody is owed anything.'**
  String get nobodyDue;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @paidAdvance.
  ///
  /// In en, this message translates to:
  /// **'Paid + advance'**
  String get paidAdvance;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Work & payments'**
  String get ledger;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @kindWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get kindWork;

  /// No description provided for @kindPayment.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get kindPayment;

  /// No description provided for @kindAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get kindAdvance;

  /// No description provided for @modeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get modeCash;

  /// No description provided for @modeUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get modeUpi;

  /// No description provided for @modeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get modeBank;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String balanceAfter(String amount);

  /// No description provided for @noLedger.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet'**
  String get noLedger;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntry;

  /// No description provided for @workEntryLocked.
  ///
  /// In en, this message translates to:
  /// **'Work entries change from the attendance or the lot they came from.'**
  String get workEntryLocked;

  /// No description provided for @workerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workerName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @dayRate.
  ///
  /// In en, this message translates to:
  /// **'Day rate (₹)'**
  String get dayRate;

  /// No description provided for @halfDayRate.
  ///
  /// In en, this message translates to:
  /// **'Half-day rate (₹)'**
  String get halfDayRate;

  /// No description provided for @halfDayHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for half the day rate'**
  String get halfDayHint;

  /// No description provided for @pieceRate.
  ///
  /// In en, this message translates to:
  /// **'Piece rate (₹)'**
  String get pieceRate;

  /// No description provided for @pieceUnit.
  ///
  /// In en, this message translates to:
  /// **'Per'**
  String get pieceUnit;

  /// No description provided for @activeWorker.
  ///
  /// In en, this message translates to:
  /// **'Still working with us'**
  String get activeWorker;

  /// No description provided for @editWorker.
  ///
  /// In en, this message translates to:
  /// **'Edit worker'**
  String get editWorker;

  /// No description provided for @amountRupees.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amountRupees;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'{rate} / {unit}'**
  String perUnit(String rate, String unit);

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get kannada;

  /// No description provided for @exportDb.
  ///
  /// In en, this message translates to:
  /// **'Export database'**
  String get exportDb;

  /// No description provided for @exportDbSub.
  ///
  /// In en, this message translates to:
  /// **'Save a safety copy to Google Drive or WhatsApp'**
  String get exportDbSub;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export: {error}'**
  String exportFailed(String error);

  /// No description provided for @dataOnPhone.
  ///
  /// In en, this message translates to:
  /// **'All data is stored on this phone. Cloud backup comes in the next update.'**
  String get dataOnPhone;

  /// No description provided for @comingNext.
  ///
  /// In en, this message translates to:
  /// **'Your farm records stay on this phone. Export a backup regularly.'**
  String get comingNext;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @xDiary.
  ///
  /// In en, this message translates to:
  /// **'Farm diary'**
  String get xDiary;

  /// No description provided for @xStock.
  ///
  /// In en, this message translates to:
  /// **'Inputs & stock'**
  String get xStock;

  /// No description provided for @xSales.
  ///
  /// In en, this message translates to:
  /// **'Sales & buyers'**
  String get xSales;

  /// No description provided for @xExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get xExpenses;

  /// No description provided for @xReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get xReports;

  /// No description provided for @xLand.
  ///
  /// In en, this message translates to:
  /// **'Land parcels'**
  String get xLand;

  /// No description provided for @xLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get xLoans;

  /// No description provided for @xInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance & schemes'**
  String get xInsurance;

  /// No description provided for @xDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get xDocuments;

  /// No description provided for @xReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get xReminders;

  /// No description provided for @xPrices.
  ///
  /// In en, this message translates to:
  /// **'Market prices'**
  String get xPrices;

  /// No description provided for @xWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather & rain'**
  String get xWeather;

  /// No description provided for @xCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get xCalendar;

  /// No description provided for @xBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get xBackup;

  /// No description provided for @xSecurity.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get xSecurity;

  /// No description provided for @xCropDetails.
  ///
  /// In en, this message translates to:
  /// **'Crop details'**
  String get xCropDetails;

  /// No description provided for @xTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get xTitle;

  /// No description provided for @xSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get xSearch;

  /// No description provided for @xAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get xAll;

  /// No description provided for @xEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Add your first entry.'**
  String get xEmpty;

  /// No description provided for @xType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get xType;

  /// No description provided for @xQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get xQuantity;

  /// No description provided for @xUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get xUnit;

  /// No description provided for @xRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get xRate;

  /// No description provided for @xAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get xAmount;

  /// No description provided for @xWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get xWorker;

  /// No description provided for @xCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get xCrop;

  /// No description provided for @xPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get xPlot;

  /// No description provided for @xDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get xDays;

  /// No description provided for @xFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get xFrom;

  /// No description provided for @xTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get xTo;

  /// No description provided for @xStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get xStatus;

  /// No description provided for @xDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get xDone;

  /// No description provided for @xPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get xPending;

  /// No description provided for @xClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get xClose;

  /// No description provided for @xContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get xContinue;

  /// No description provided for @xChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get xChoose;

  /// No description provided for @xNoSelection.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get xNoSelection;

  /// No description provided for @xError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check the values and try again.'**
  String get xError;

  /// No description provided for @xPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a value greater than zero'**
  String get xPositive;

  /// No description provided for @xInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check this value'**
  String get xInvalid;

  /// No description provided for @xActivity.
  ///
  /// In en, this message translates to:
  /// **'Add work'**
  String get xActivity;

  /// No description provided for @xFertiliser.
  ///
  /// In en, this message translates to:
  /// **'Fertiliser'**
  String get xFertiliser;

  /// No description provided for @xSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get xSpray;

  /// No description provided for @xIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get xIrrigation;

  /// No description provided for @xWeeding.
  ///
  /// In en, this message translates to:
  /// **'Weeding'**
  String get xWeeding;

  /// No description provided for @xMulching.
  ///
  /// In en, this message translates to:
  /// **'Mulching'**
  String get xMulching;

  /// No description provided for @xCropCare.
  ///
  /// In en, this message translates to:
  /// **'Crop care'**
  String get xCropCare;

  /// No description provided for @xOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get xOther;

  /// No description provided for @xInputsUsed.
  ///
  /// In en, this message translates to:
  /// **'Inputs used'**
  String get xInputsUsed;

  /// No description provided for @xAddInput.
  ///
  /// In en, this message translates to:
  /// **'Add input'**
  String get xAddInput;

  /// No description provided for @xAddLabour.
  ///
  /// In en, this message translates to:
  /// **'Add labour'**
  String get xAddLabour;

  /// No description provided for @xRemindOn.
  ///
  /// In en, this message translates to:
  /// **'Remind me on'**
  String get xRemindOn;

  /// No description provided for @xAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get xAddReminder;

  /// No description provided for @xPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get xPhoto;

  /// No description provided for @xVoice.
  ///
  /// In en, this message translates to:
  /// **'Dictate note'**
  String get xVoice;

  /// No description provided for @xListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… tap to stop'**
  String get xListening;

  /// No description provided for @xVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is unavailable. Check the phone language and microphone permission.'**
  String get xVoiceUnavailable;

  /// No description provided for @xStockName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get xStockName;

  /// No description provided for @xMinimum.
  ///
  /// In en, this message translates to:
  /// **'Low-stock level'**
  String get xMinimum;

  /// No description provided for @xPurchase.
  ///
  /// In en, this message translates to:
  /// **'Record purchase'**
  String get xPurchase;

  /// No description provided for @xSupplier.
  ///
  /// In en, this message translates to:
  /// **'Shop / supplier'**
  String get xSupplier;

  /// No description provided for @xAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get xAvailable;

  /// No description provided for @xValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get xValue;

  /// No description provided for @xLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get xLowStock;

  /// No description provided for @xAverageCost.
  ///
  /// In en, this message translates to:
  /// **'Average purchase cost'**
  String get xAverageCost;

  /// No description provided for @xStockHint.
  ///
  /// In en, this message translates to:
  /// **'Stock is valued at moving average purchase cost. Diary usage reduces stock and books the cost once.'**
  String get xStockHint;

  /// No description provided for @xCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get xCategory;

  /// No description provided for @xElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get xElectricity;

  /// No description provided for @xDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get xDiesel;

  /// No description provided for @xRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get xRepairs;

  /// No description provided for @xTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get xTools;

  /// No description provided for @xTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get xTransport;

  /// No description provided for @xIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get xIncome;

  /// No description provided for @xCosts.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get xCosts;

  /// No description provided for @xProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit / loss'**
  String get xProfit;

  /// No description provided for @xSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get xSeason;

  /// No description provided for @xPreviousSeason.
  ///
  /// In en, this message translates to:
  /// **'Previous season'**
  String get xPreviousSeason;

  /// No description provided for @xLabourCost.
  ///
  /// In en, this message translates to:
  /// **'Labour cost'**
  String get xLabourCost;

  /// No description provided for @xInputCost.
  ///
  /// In en, this message translates to:
  /// **'Inputs consumed'**
  String get xInputCost;

  /// No description provided for @xInterestPaid.
  ///
  /// In en, this message translates to:
  /// **'Interest paid'**
  String get xInterestPaid;

  /// No description provided for @xPremiums.
  ///
  /// In en, this message translates to:
  /// **'Insurance premiums'**
  String get xPremiums;

  /// No description provided for @xExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get xExportPdf;

  /// No description provided for @xExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Share Excel'**
  String get xExportExcel;

  /// No description provided for @xShareStatement.
  ///
  /// In en, this message translates to:
  /// **'Share statement'**
  String get xShareStatement;

  /// No description provided for @xReportBasis.
  ///
  /// In en, this message translates to:
  /// **'Accrual report: sales less wages earned, inputs consumed, expenses, interest paid and premiums. Stock purchases and wage payments are not counted twice.'**
  String get xReportBasis;

  /// No description provided for @xSurvey.
  ///
  /// In en, this message translates to:
  /// **'Survey number'**
  String get xSurvey;

  /// No description provided for @xHissa.
  ///
  /// In en, this message translates to:
  /// **'Hissa'**
  String get xHissa;

  /// No description provided for @xLender.
  ///
  /// In en, this message translates to:
  /// **'Lender'**
  String get xLender;

  /// No description provided for @xLenderKind.
  ///
  /// In en, this message translates to:
  /// **'Lender type'**
  String get xLenderKind;

  /// No description provided for @xBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get xBank;

  /// No description provided for @xSociety.
  ///
  /// In en, this message translates to:
  /// **'Society / PACS'**
  String get xSociety;

  /// No description provided for @xPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private lender'**
  String get xPrivate;

  /// No description provided for @xLoanKind.
  ///
  /// In en, this message translates to:
  /// **'Loan type'**
  String get xLoanKind;

  /// No description provided for @xCropLoan.
  ///
  /// In en, this message translates to:
  /// **'Crop / KCC'**
  String get xCropLoan;

  /// No description provided for @xTermLoan.
  ///
  /// In en, this message translates to:
  /// **'Term loan'**
  String get xTermLoan;

  /// No description provided for @xGoldLoan.
  ///
  /// In en, this message translates to:
  /// **'Gold loan'**
  String get xGoldLoan;

  /// No description provided for @xHandLoan.
  ///
  /// In en, this message translates to:
  /// **'Hand loan'**
  String get xHandLoan;

  /// No description provided for @xSanctioned.
  ///
  /// In en, this message translates to:
  /// **'Sanctioned limit'**
  String get xSanctioned;

  /// No description provided for @xAnnualRate.
  ///
  /// In en, this message translates to:
  /// **'Annual interest %'**
  String get xAnnualRate;

  /// No description provided for @xSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple interest'**
  String get xSimple;

  /// No description provided for @xCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound interest'**
  String get xCompound;

  /// No description provided for @xCompounding.
  ///
  /// In en, this message translates to:
  /// **'Compounding interval (months)'**
  String get xCompounding;

  /// No description provided for @xTenure.
  ///
  /// In en, this message translates to:
  /// **'Tenure (months)'**
  String get xTenure;

  /// No description provided for @xSecurityLand.
  ///
  /// In en, this message translates to:
  /// **'Land given as security'**
  String get xSecurityLand;

  /// No description provided for @xOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding principal'**
  String get xOutstanding;

  /// No description provided for @xAccruedInterest.
  ///
  /// In en, this message translates to:
  /// **'Estimated accrued interest'**
  String get xAccruedInterest;

  /// No description provided for @xWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get xWithdrawal;

  /// No description provided for @xPrincipalPayment.
  ///
  /// In en, this message translates to:
  /// **'Principal repayment'**
  String get xPrincipalPayment;

  /// No description provided for @xInterestPayment.
  ///
  /// In en, this message translates to:
  /// **'Interest payment'**
  String get xInterestPayment;

  /// No description provided for @xCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get xCharge;

  /// No description provided for @xAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get xAddTransaction;

  /// No description provided for @xLoanEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate uses actual days / 365. Enter principal and interest payments separately. Verify against the lender statement.'**
  String get xLoanEstimate;

  /// No description provided for @xConcession.
  ///
  /// In en, this message translates to:
  /// **'Timely payment keeps a lower interest rate'**
  String get xConcession;

  /// No description provided for @xActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get xActive;

  /// No description provided for @xClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get xClosed;

  /// No description provided for @xMembership.
  ///
  /// In en, this message translates to:
  /// **'Society memberships'**
  String get xMembership;

  /// No description provided for @xMemberNumber.
  ///
  /// In en, this message translates to:
  /// **'Member number'**
  String get xMemberNumber;

  /// No description provided for @xOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get xOrganization;

  /// No description provided for @xShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get xShares;

  /// No description provided for @xShareValue.
  ///
  /// In en, this message translates to:
  /// **'Value per share'**
  String get xShareValue;

  /// No description provided for @xDividend.
  ///
  /// In en, this message translates to:
  /// **'Dividend'**
  String get xDividend;

  /// No description provided for @xSharePurchase.
  ///
  /// In en, this message translates to:
  /// **'Share purchase'**
  String get xSharePurchase;

  /// No description provided for @xPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get xPolicies;

  /// No description provided for @xClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get xClaims;

  /// No description provided for @xSchemes.
  ///
  /// In en, this message translates to:
  /// **'Schemes / subsidies'**
  String get xSchemes;

  /// No description provided for @xScheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme name'**
  String get xScheme;

  /// No description provided for @xPolicyNumber.
  ///
  /// In en, this message translates to:
  /// **'Policy / application number'**
  String get xPolicyNumber;

  /// No description provided for @xPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium paid'**
  String get xPremium;

  /// No description provided for @xEnrolBy.
  ///
  /// In en, this message translates to:
  /// **'Enrolment deadline'**
  String get xEnrolBy;

  /// No description provided for @xLossDate.
  ///
  /// In en, this message translates to:
  /// **'Date of loss'**
  String get xLossDate;

  /// No description provided for @xFiledDate.
  ///
  /// In en, this message translates to:
  /// **'Claim filed on'**
  String get xFiledDate;

  /// No description provided for @xClaimed.
  ///
  /// In en, this message translates to:
  /// **'Amount claimed'**
  String get xClaimed;

  /// No description provided for @xReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get xReceived;

  /// No description provided for @xReceivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received on'**
  String get xReceivedOn;

  /// No description provided for @xDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get xDepartment;

  /// No description provided for @xAppliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied on'**
  String get xAppliedOn;

  /// No description provided for @xApplicationNumber.
  ///
  /// In en, this message translates to:
  /// **'Application number'**
  String get xApplicationNumber;

  /// No description provided for @xSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy amount'**
  String get xSubsidy;

  /// No description provided for @xDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get xDraft;

  /// No description provided for @xFiled.
  ///
  /// In en, this message translates to:
  /// **'Filed'**
  String get xFiled;

  /// No description provided for @xApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get xApproved;

  /// No description provided for @xRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get xRejected;

  /// No description provided for @xPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get xPaid;

  /// No description provided for @xExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get xExpired;

  /// No description provided for @xAddDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get xAddDocument;

  /// No description provided for @xOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get xOpen;

  /// No description provided for @xCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get xCamera;

  /// No description provided for @xGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get xGallery;

  /// No description provided for @xFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get xFile;

  /// No description provided for @xDocumentKind.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get xDocumentKind;

  /// No description provided for @xRtc.
  ///
  /// In en, this message translates to:
  /// **'RTC / land record'**
  String get xRtc;

  /// No description provided for @xBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get xBill;

  /// No description provided for @xPolicy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get xPolicy;

  /// No description provided for @xDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get xDueOn;

  /// No description provided for @xMillimetres.
  ///
  /// In en, this message translates to:
  /// **'Rainfall (mm)'**
  String get xMillimetres;

  /// No description provided for @xMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get xMarket;

  /// No description provided for @xSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get xSource;

  /// No description provided for @xGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade / product'**
  String get xGrade;

  /// No description provided for @xMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum price'**
  String get xMinPrice;

  /// No description provided for @xMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum price'**
  String get xMaxPrice;

  /// No description provided for @xModalPrice.
  ///
  /// In en, this message translates to:
  /// **'Typical / modal price'**
  String get xModalPrice;

  /// No description provided for @xPricePerKg.
  ///
  /// In en, this message translates to:
  /// **'₹ per kg (nuts / bunches per unit)'**
  String get xPricePerKg;

  /// No description provided for @xPriceAlert.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get xPriceAlert;

  /// No description provided for @xTarget.
  ///
  /// In en, this message translates to:
  /// **'Target price'**
  String get xTarget;

  /// No description provided for @xAbove.
  ///
  /// In en, this message translates to:
  /// **'At or above'**
  String get xAbove;

  /// No description provided for @xBelow.
  ///
  /// In en, this message translates to:
  /// **'At or below'**
  String get xBelow;

  /// No description provided for @xHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get xHistory;

  /// No description provided for @xRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get xRefresh;

  /// No description provided for @xLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get xLastUpdated;

  /// No description provided for @xOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline / saved data'**
  String get xOffline;

  /// No description provided for @xNoWeather.
  ///
  /// In en, this message translates to:
  /// **'Set the farm location to download a forecast.'**
  String get xNoWeather;

  /// No description provided for @xLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get xLatitude;

  /// No description provided for @xLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get xLongitude;

  /// No description provided for @xUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use phone location'**
  String get xUseLocation;

  /// No description provided for @xLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm location'**
  String get xLocation;

  /// No description provided for @xForecast.
  ///
  /// In en, this message translates to:
  /// **'Seven-day forecast'**
  String get xForecast;

  /// No description provided for @xRainChance.
  ///
  /// In en, this message translates to:
  /// **'Rain chance'**
  String get xRainChance;

  /// No description provided for @xRainLog.
  ///
  /// In en, this message translates to:
  /// **'Rain gauge log'**
  String get xRainLog;

  /// No description provided for @xRainWarning.
  ///
  /// In en, this message translates to:
  /// **'Rain expected: cover drying lots'**
  String get xRainWarning;

  /// No description provided for @xVariety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get xVariety;

  /// No description provided for @xPlantedOn.
  ///
  /// In en, this message translates to:
  /// **'Planting date'**
  String get xPlantedOn;

  /// No description provided for @xBearing.
  ///
  /// In en, this message translates to:
  /// **'Bearing crop'**
  String get xBearing;

  /// No description provided for @xRatoon.
  ///
  /// In en, this message translates to:
  /// **'Ratoon number'**
  String get xRatoon;

  /// No description provided for @xTrailedOn.
  ///
  /// In en, this message translates to:
  /// **'Trailed on which palms'**
  String get xTrailedOn;

  /// No description provided for @xCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get xCount;

  /// No description provided for @xProduce.
  ///
  /// In en, this message translates to:
  /// **'Coconut, pepper & banana'**
  String get xProduce;

  /// No description provided for @xProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get xProduct;

  /// No description provided for @xNuts.
  ///
  /// In en, this message translates to:
  /// **'Nuts'**
  String get xNuts;

  /// No description provided for @xBunches.
  ///
  /// In en, this message translates to:
  /// **'Bunches'**
  String get xBunches;

  /// No description provided for @xCopra.
  ///
  /// In en, this message translates to:
  /// **'Copra'**
  String get xCopra;

  /// No description provided for @xThreshing.
  ///
  /// In en, this message translates to:
  /// **'Threshing'**
  String get xThreshing;

  /// No description provided for @xDehusking.
  ///
  /// In en, this message translates to:
  /// **'Dehusking'**
  String get xDehusking;

  /// No description provided for @xFinishProcessing.
  ///
  /// In en, this message translates to:
  /// **'Record finished quantity'**
  String get xFinishProcessing;

  /// No description provided for @xFinishedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Finished quantity'**
  String get xFinishedQuantity;

  /// No description provided for @xStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get xStorage;

  /// No description provided for @xPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get xPlace;

  /// No description provided for @xBags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get xBags;

  /// No description provided for @xHarvestQuantity.
  ///
  /// In en, this message translates to:
  /// **'Harvest quantity'**
  String get xHarvestQuantity;

  /// No description provided for @xRecordSale.
  ///
  /// In en, this message translates to:
  /// **'Record sale'**
  String get xRecordSale;

  /// No description provided for @xRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record buyer payment'**
  String get xRecordPayment;

  /// No description provided for @xBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get xBuyer;

  /// No description provided for @xDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get xDeductions;

  /// No description provided for @xBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get xBalance;

  /// No description provided for @xStartDrying.
  ///
  /// In en, this message translates to:
  /// **'Start drying'**
  String get xStartDrying;

  /// No description provided for @xFinishDrying.
  ///
  /// In en, this message translates to:
  /// **'Finish drying'**
  String get xFinishDrying;

  /// No description provided for @xRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get xRestore;

  /// No description provided for @xCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get xCreateBackup;

  /// No description provided for @xRestoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This replaces the app records with the selected backup. A safety backup is created first. Continue?'**
  String get xRestoreWarning;

  /// No description provided for @xBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Includes the database, photos and documents. Keep a copy outside this phone.'**
  String get xBackupHint;

  /// No description provided for @xLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Require phone PIN or fingerprint'**
  String get xLockEnabled;

  /// No description provided for @xUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Dhara Mitra'**
  String get xUnlock;

  /// No description provided for @xAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication was not completed'**
  String get xAuthenticationFailed;

  /// No description provided for @xEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get xEnableNotifications;

  /// No description provided for @xCloudSetup.
  ///
  /// In en, this message translates to:
  /// **'Cloud setup'**
  String get xCloudSetup;

  /// No description provided for @xCloudNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup and automatic market feeds need account setup. Local records, manual prices and backups work now.'**
  String get xCloudNotConfigured;

  /// No description provided for @xSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get xSaveFailed;

  /// No description provided for @xInterestMethod.
  ///
  /// In en, this message translates to:
  /// **'Interest method'**
  String get xInterestMethod;

  /// No description provided for @xTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get xTransactions;

  /// No description provided for @xWeatherSource.
  ///
  /// In en, this message translates to:
  /// **'Forecast: Open-Meteo. Forecasts are estimates.'**
  String get xWeatherSource;

  /// No description provided for @xLoanDues.
  ///
  /// In en, this message translates to:
  /// **'Upcoming loan dues'**
  String get xLoanDues;

  /// No description provided for @xSpentMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get xSpentMonth;

  /// No description provided for @xPerAcre.
  ///
  /// In en, this message translates to:
  /// **'Profit per acre'**
  String get xPerAcre;

  /// No description provided for @xYield.
  ///
  /// In en, this message translates to:
  /// **'Yield'**
  String get xYield;

  /// No description provided for @xOutTurn.
  ///
  /// In en, this message translates to:
  /// **'Dry out-turn'**
  String get xOutTurn;

  /// No description provided for @xDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'This record is used by other records. Remove those links first.'**
  String get xDeleteBlocked;

  /// No description provided for @xAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds the balance'**
  String get xAmountTooLarge;

  /// No description provided for @xNotEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds available stock'**
  String get xNotEnoughStock;

  /// No description provided for @xCannotReduceSold.
  ///
  /// In en, this message translates to:
  /// **'Cannot reduce a grade below the quantity already sold'**
  String get xCannotReduceSold;

  /// No description provided for @xCheckDates.
  ///
  /// In en, this message translates to:
  /// **'Check the order of the dates'**
  String get xCheckDates;

  /// No description provided for @xOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get xOverdue;

  /// No description provided for @xDays7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get xDays7;

  /// No description provided for @xDays30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get xDays30;

  /// No description provided for @xYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get xYear;

  /// No description provided for @xPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get xPhotoSaved;

  /// No description provided for @xNoLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'Manual price entry works offline. Automatic feeds need cloud setup.'**
  String get xNoLiveFeed;

  /// No description provided for @xLabourShare.
  ///
  /// In en, this message translates to:
  /// **'Labour share of costs'**
  String get xLabourShare;

  /// No description provided for @xApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get xApplied;

  /// No description provided for @xBackupInvalid.
  ///
  /// In en, this message translates to:
  /// **'Backup is invalid or incomplete. Use a full Dhara Mitra ZIP backup including its attachments.'**
  String get xBackupInvalid;

  /// No description provided for @xPerPalm.
  ///
  /// In en, this message translates to:
  /// **'Chali kg per palm'**
  String get xPerPalm;

  /// No description provided for @xAllocation.
  ///
  /// In en, this message translates to:
  /// **'Shared records are split equally between their selected crops and plots. Unassigned costs appear in the whole-farm report.'**
  String get xAllocation;

  /// No description provided for @xAttendanceUsed.
  ///
  /// In en, this message translates to:
  /// **'This attendance is absent or its daily wage is already fully allocated. Check attendance and split shared days between jobs; record extra piecework separately.'**
  String get xAttendanceUsed;

  /// No description provided for @fChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose farm on map'**
  String get fChooseLocation;

  /// No description provided for @fMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap your farm to place a pin. Zoom in to move it precisely.'**
  String get fMapHint;

  /// No description provided for @fMapOffline.
  ///
  /// In en, this message translates to:
  /// **'Map needs internet. You can go back and add the location later.'**
  String get fMapOffline;

  /// No description provided for @fLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not find your location. Tap the map instead.'**
  String get fLocationUnavailable;

  /// No description provided for @fUsePin.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get fUsePin;

  /// No description provided for @fLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Farm location selected'**
  String get fLocationSaved;

  /// No description provided for @fLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Choose your farm for local weather; you can add it later.'**
  String get fLocationOptional;

  /// No description provided for @fMobileError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit Indian mobile number'**
  String get fMobileError;

  /// No description provided for @fTelephone.
  ///
  /// In en, this message translates to:
  /// **'Landline with STD code (optional)'**
  String get fTelephone;

  /// No description provided for @fTelephoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Indian landline with STD code'**
  String get fTelephoneError;

  /// No description provided for @fCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get fCall;

  /// No description provided for @fCallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the dialler. Check the number.'**
  String get fCallUnavailable;

  /// No description provided for @fAddRole.
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get fAddRole;

  /// No description provided for @fRoleHint.
  ///
  /// In en, this message translates to:
  /// **'For example: irrigation, tractor driver'**
  String get fRoleHint;

  /// No description provided for @fApplyAll.
  ///
  /// In en, this message translates to:
  /// **'Apply this work to everyone'**
  String get fApplyAll;

  /// No description provided for @fCollections.
  ///
  /// In en, this message translates to:
  /// **'Collected from farm'**
  String get fCollections;

  /// No description provided for @fCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'Record each pickup. Select one or more pickups when you are ready to dry them.'**
  String get fCollectionHint;

  /// No description provided for @fNewCollection.
  ///
  /// In en, this message translates to:
  /// **'Add collection'**
  String get fNewCollection;

  /// No description provided for @fDrySelected.
  ///
  /// In en, this message translates to:
  /// **'Dry selected together'**
  String get fDrySelected;

  /// No description provided for @fUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Waiting for drying'**
  String get fUnassigned;

  /// No description provided for @fAssigned.
  ///
  /// In en, this message translates to:
  /// **'In drying lot'**
  String get fAssigned;

  /// No description provided for @fBagsMode.
  ///
  /// In en, this message translates to:
  /// **'Bags until peeling'**
  String get fBagsMode;

  /// No description provided for @fKgMode.
  ///
  /// In en, this message translates to:
  /// **'Kilograms throughout'**
  String get fKgMode;

  /// No description provided for @fQuantityMode.
  ///
  /// In en, this message translates to:
  /// **'How do you measure your harvest?'**
  String get fQuantityMode;

  /// No description provided for @fFreshBags.
  ///
  /// In en, this message translates to:
  /// **'Bags collected'**
  String get fFreshBags;

  /// No description provided for @fDriedBags.
  ///
  /// In en, this message translates to:
  /// **'Dried bags brought home'**
  String get fDriedBags;

  /// No description provided for @fQuantityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not measured yet'**
  String get fQuantityUnknown;

  /// No description provided for @fMixedUnits.
  ///
  /// In en, this message translates to:
  /// **'Choose collections with the same unit. Bags and kg cannot be added together.'**
  String get fMixedUnits;

  /// No description provided for @fCollectionLocked.
  ///
  /// In en, this message translates to:
  /// **'This collection is already in a lot. Open the lot to view it.'**
  String get fCollectionLocked;

  /// No description provided for @fCollectionDateError.
  ///
  /// In en, this message translates to:
  /// **'Drying cannot start before the latest collection date.'**
  String get fCollectionDateError;

  /// No description provided for @fFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get fFertilizer;

  /// No description provided for @fFarms.
  ///
  /// In en, this message translates to:
  /// **'My farms'**
  String get fFarms;

  /// No description provided for @fAddFarm.
  ///
  /// In en, this message translates to:
  /// **'Add farm'**
  String get fAddFarm;

  /// No description provided for @fDeleteFarm.
  ///
  /// In en, this message translates to:
  /// **'Delete farm'**
  String get fDeleteFarm;

  /// No description provided for @fDeleteFarmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this farm and all its records and attached files from this device? This cannot be undone. Exported backups will remain.'**
  String get fDeleteFarmBody;

  /// No description provided for @fFarmSeparate.
  ///
  /// In en, this message translates to:
  /// **'Each farm has its own workers, accounts and records. Switch farms before entering work.'**
  String get fFarmSeparate;

  /// No description provided for @fFarmBackup.
  ///
  /// In en, this message translates to:
  /// **'This backup contains the selected farm. Back up each farm separately.'**
  String get fFarmBackup;

  /// No description provided for @fBackupAll.
  ///
  /// In en, this message translates to:
  /// **'Back up all farms'**
  String get fBackupAll;

  /// No description provided for @fImportFarms.
  ///
  /// In en, this message translates to:
  /// **'Import farms from backup'**
  String get fImportFarms;

  /// No description provided for @fImportHint.
  ///
  /// In en, this message translates to:
  /// **'Adds farms as new profiles. Your current farms are kept unchanged.'**
  String get fImportHint;

  /// No description provided for @fImported.
  ///
  /// In en, this message translates to:
  /// **'Farms imported. Open My farms to choose one.'**
  String get fImported;

  /// No description provided for @wOpeningShares.
  ///
  /// In en, this message translates to:
  /// **'Opening shares'**
  String get wOpeningShares;

  /// No description provided for @wTransactionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a transaction to edit; hold to remove.'**
  String get wTransactionHint;

  /// No description provided for @wDailyHint.
  ///
  /// In en, this message translates to:
  /// **'Daily work reuses attendance wages. Enter 0.5 for half a day. Split a shared day between jobs; record extra piecework separately. Existing attendance rates apply.'**
  String get wDailyHint;

  /// No description provided for @nFarmTools.
  ///
  /// In en, this message translates to:
  /// **'Farm tools'**
  String get nFarmTools;
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
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
