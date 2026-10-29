// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aWelcome => 'Welcome to Dhara Mitra';

  @override
  String get aGoogle => 'Continue with Google';

  @override
  String get aEmail => 'Sign in with email';

  @override
  String get aLocal => 'Continue locally';

  @override
  String get aLocalMode => 'Local mode';

  @override
  String get aAccount => 'Account';

  @override
  String get aSignOut => 'Sign out';

  @override
  String get aChooseMode => 'Choose how to use Dhara Mitra';

  @override
  String get aLocalWarning =>
      'Your data is stored only on this device. If you uninstall the app, clear its data, or lose your phone, your records cannot be recovered unless you have manually saved a backup outside the app.';

  @override
  String get aAcknowledge => 'I understand that I must save backups manually.';

  @override
  String get aManualBackup =>
      'Cloud backup is not available yet. Signing in does not back up your records. Save manual backups outside the app.';

  @override
  String get aSeparateRecords =>
      'Accounts have separate farm records on this device. Your existing local farms stay in local mode. To move them, export an all-farm backup in local mode, then import it after signing in.';

  @override
  String get aNotConfigured =>
      'Account sign-in is not configured in this build. You can continue locally and save manual backups.';

  @override
  String get aUnavailable =>
      'Account sign-in is temporarily unavailable. Try again later or continue locally.';

  @override
  String get aEmailAddress => 'Email address';

  @override
  String get aPassword => 'Password';

  @override
  String get aConfirmPassword => 'Confirm password';

  @override
  String get aSignIn => 'Sign in';

  @override
  String get aCreateAccount => 'Create an account';

  @override
  String get aForgotPassword => 'Forgot password?';

  @override
  String get aSendReset => 'Send password reset email';

  @override
  String get aResetSent =>
      'If an account exists for this email, a password reset link has been sent. Open it on this device.';

  @override
  String get aVerifyEmail =>
      'Check your email to confirm your account, then sign in. Open the confirmation link on this device.';

  @override
  String get aNewPassword => 'Set a new password';

  @override
  String get aSavePassword => 'Save new password';

  @override
  String get aInvalidEmail => 'Enter a valid email address.';

  @override
  String get aPasswordRequired => 'Enter your password.';

  @override
  String get aPasswordLength => 'Use at least 8 characters.';

  @override
  String get aPasswordMismatch => 'Passwords do not match.';

  @override
  String get aAuthFailed =>
      'Unable to sign in. Check your details and email confirmation, or try again when online.';

  @override
  String get aRequestFailed =>
      'Unable to complete this request. Check your connection and try again.';

  @override
  String get aBrowserOpened =>
      'Finish signing in in your browser. If you cancelled, you can try again or continue locally.';

  @override
  String get aLeaveLocal => 'Choose a sign-in method';

  @override
  String get aSignOutInfo =>
      'Your records will stay on this device. Sign back in to this account to access them. Cloud backup is not available yet.';

  @override
  String get aBackupRestore => 'Backup and restore';

  @override
  String get aRestoreLocal => 'Restore a backup in local mode';

  @override
  String get aShowPassword => 'Show password';

  @override
  String get aHidePassword => 'Hide password';

  @override
  String get aBack => 'Back';

  @override
  String get aCancelRecovery => 'Cancel and sign out';

  @override
  String get appName => 'Dhara Mitra';

  @override
  String get navHome => 'Home';

  @override
  String get navHarvest => 'Harvest';

  @override
  String get navLabour => 'Labour';

  @override
  String get navMore => 'More';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get optional => 'optional';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Enter a number';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get note => 'Note';

  @override
  String get total => 'Total';

  @override
  String get today => 'Today';

  @override
  String get saved => 'Saved';

  @override
  String get lakhUnit => 'L';

  @override
  String get kgUnit => 'kg';

  @override
  String kgValue(String kg) {
    return '$kg kg';
  }

  @override
  String get confirmDelete => 'Delete?';

  @override
  String get deleteCannotUndo => 'This removes it from the app.';

  @override
  String get cropAreca => 'Arecanut';

  @override
  String get cropCoconut => 'Coconut';

  @override
  String get cropPepper => 'Pepper';

  @override
  String get cropBanana => 'Banana';

  @override
  String get setupTitle => 'Set up your farm';

  @override
  String get setupIntro =>
      'Everything is saved on this phone and works without internet. You can change all of this later under More.';

  @override
  String get farmName => 'Farm name';

  @override
  String get farmNameHint => 'e.g. Bhat Thota';

  @override
  String get village => 'Village';

  @override
  String get villageHint => 'e.g. Kemminje, Puttur';

  @override
  String get seasonStarts => 'Season starts in';

  @override
  String get plotsTitle => 'Plots';

  @override
  String get setupPlotsHint =>
      'Add each part of the garden you look after separately, like Upper plot and Lower plot.';

  @override
  String get addPlot => 'Add plot';

  @override
  String get editPlot => 'Edit plot';

  @override
  String get startUsing => 'Start using Dhara Mitra';

  @override
  String get needOnePlot => 'Add at least one plot';

  @override
  String get plotName => 'Plot name';

  @override
  String get plotNameHint => 'e.g. Upper plot';

  @override
  String get acres => 'Acres';

  @override
  String acresGuntas(int acres, int guntas) {
    return '$acres acres $guntas guntas';
  }

  @override
  String get soil => 'Soil';

  @override
  String get soilHint => 'e.g. Laterite';

  @override
  String get irrigation => 'Irrigation';

  @override
  String get irrSprinkler => 'Sprinklers';

  @override
  String get irrDrip => 'Drip';

  @override
  String get irrHose => 'Hose';

  @override
  String get irrNone => 'Rain-fed';

  @override
  String get arecaPalms => 'Areca palms';

  @override
  String get coconutTrees => 'Coconut trees';

  @override
  String get pepperVines => 'Pepper vines';

  @override
  String get bananaClumps => 'Banana plants';

  @override
  String palmsCount(int n) {
    return '$n palms';
  }

  @override
  String get deletePlot => 'Delete plot';

  @override
  String get namaskara => 'Namaskara';

  @override
  String get dryingNow => 'Drying now';

  @override
  String get inStorage => 'In storage';

  @override
  String get waitingForYou => 'Next step waiting';

  @override
  String dayOf(int day, int target) {
    return 'Day $day of ~$target';
  }

  @override
  String expectedDone(String date) {
    return 'Expected done $date';
  }

  @override
  String get logRainCover => 'Log rain cover';

  @override
  String get coverLogged => 'Rain cover logged';

  @override
  String get qaHarvest => 'New harvest';

  @override
  String get qaAttendance => 'Attendance';

  @override
  String get qaPay => 'Pay worker';

  @override
  String get money => 'Money';

  @override
  String get toPayWorkers => 'To pay workers';

  @override
  String get toReceive => 'To receive';

  @override
  String daysInStore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days in store',
      one: '1 day in store',
    );
    return '$_temp0';
  }

  @override
  String kgLeft(String kg) {
    return '$kg kg left';
  }

  @override
  String get homeEmpty =>
      'Start by recording a harvest. The app counts the drying days, peeling cost and profit for you.';

  @override
  String get lotsTitle => 'Harvest lots';

  @override
  String get filterActive => 'Active';

  @override
  String get filterSold => 'Sold';

  @override
  String get filterAll => 'All';

  @override
  String get newHarvest => 'New harvest';

  @override
  String get noLots =>
      'No lots here yet. Tap New harvest when the climbers finish a round.';

  @override
  String get stageHarvest => 'Harvested';

  @override
  String get stageDrying => 'Drying';

  @override
  String get stagePeeling => 'Peeling';

  @override
  String get stageGrading => 'Grading';

  @override
  String get stageStorage => 'Storage';

  @override
  String get stageSold => 'Sold';

  @override
  String seasonLabel(String season) {
    return 'Season $season';
  }

  @override
  String get harvestTitle => 'New harvest';

  @override
  String get lotTitle => 'Name';

  @override
  String get lotTitleHint => 'e.g. Harvest round 1 · Upper plot';

  @override
  String harvestRound(int n) {
    return 'Harvest round $n';
  }

  @override
  String get harvestDate => 'Harvest date';

  @override
  String get whichPlots => 'Which plots?';

  @override
  String get palmsClimbed => 'Palms climbed';

  @override
  String get freshKg => 'Fresh nuts (kg)';

  @override
  String get labourSection => 'Labour';

  @override
  String get addLabourLine => 'Add worker';

  @override
  String get noLabour => 'No labour added';

  @override
  String get worker => 'Worker';

  @override
  String get chooseWorker => 'Choose worker';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get rateRupees => 'Rate (₹)';

  @override
  String get amount => 'Amount';

  @override
  String get unitDay => 'day';

  @override
  String get unitPalm => 'palm';

  @override
  String get unitTree => 'tree';

  @override
  String get unitKg => 'kg';

  @override
  String get unitNut => 'nut';

  @override
  String get unitLump => 'lump sum';

  @override
  String get labourCost => 'Labour cost';

  @override
  String get noWorkersYet => 'Add workers under Labour first.';

  @override
  String get secHarvest => 'Harvest';

  @override
  String get secDrying => 'Drying';

  @override
  String get secPeeling => 'Peeling';

  @override
  String get secGrading => 'Grading';

  @override
  String get secStorage => 'Storage';

  @override
  String get secSales => 'Sales';

  @override
  String get secMoney => 'Money';

  @override
  String get secLog => 'Log';

  @override
  String get plots => 'Plots';

  @override
  String get startDrying => 'Start drying';

  @override
  String get started => 'Started';

  @override
  String get finished => 'Finished';

  @override
  String get daysOnYard => 'Days on the yard';

  @override
  String get yard => 'Yard';

  @override
  String get yardHint => 'e.g. Main yard · tarpaulin';

  @override
  String get targetDays => 'Expected drying days';

  @override
  String get coveredForRain => 'Covered for rain';

  @override
  String get turned => 'Turned';

  @override
  String nTimes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times',
      one: 'once',
      zero: 'not yet',
    );
    return '$_temp0';
  }

  @override
  String get logTurning => 'Log turning';

  @override
  String get turningLogged => 'Turning logged';

  @override
  String get finishDrying => 'Drying finished';

  @override
  String get driedKg => 'Dried nuts in husk (kg)';

  @override
  String get recordPeeling => 'Record peeling';

  @override
  String get chaliKg => 'Chali after peeling (kg)';

  @override
  String get outTurn => 'Out-turn';

  @override
  String get peelers => 'Peelers';

  @override
  String get peelingCost => 'Total peeling cost';

  @override
  String get enterGrades => 'Enter grades';

  @override
  String get editGrades => 'Edit grades';

  @override
  String get gradeChali => 'Chali';

  @override
  String get gradePatora => 'Patora';

  @override
  String get gradeUlliGadde => 'Ulli gadde';

  @override
  String get gradeKarigotu => 'Karigotu';

  @override
  String get gradeKoka => 'Koka';

  @override
  String get gradedTotal => 'Graded total';

  @override
  String get skipGrading =>
      'Sold or stored without grading? Go straight to storage or sale.';

  @override
  String get moveToStorage => 'Move to storage';

  @override
  String get storagePlace => 'Place';

  @override
  String get storagePlaceHint => 'e.g. Attic store room';

  @override
  String get bags => 'Bags';

  @override
  String get storedSince => 'Stored since';

  @override
  String get daysInStorage => 'Days in storage';

  @override
  String get priceWhenStored => 'Price when stored (₹/kg)';

  @override
  String get valueAtStoredPrice => 'Value of what\'s left at the stored price';

  @override
  String get logCheck => 'Log check';

  @override
  String get checkKind => 'What was checked?';

  @override
  String get checkValue => 'Reading';

  @override
  String get checkValueHint => 'e.g. 11% or no weevils';

  @override
  String get recordSale => 'Record sale';

  @override
  String get soldSoFar => 'Sold so far';

  @override
  String get left => 'Left';

  @override
  String get noSales => 'Nothing sold yet';

  @override
  String get notStartedYet => 'Not started yet';

  @override
  String get saleTitle => 'Record sale';

  @override
  String get buyer => 'Buyer';

  @override
  String get chooseBuyer => 'Choose buyer';

  @override
  String get newBuyer => 'New buyer';

  @override
  String get buyerName => 'Buyer name';

  @override
  String get buyerNameHint => 'e.g. CAMPCO · Puttur branch';

  @override
  String get buyerCampco => 'CAMPCO';

  @override
  String get buyerTrader => 'Trader';

  @override
  String get buyerApmc => 'APMC agent';

  @override
  String get buyerOther => 'Other';

  @override
  String get whatWasSold => 'What was sold';

  @override
  String get ratePerKg => 'Rate (₹/kg)';

  @override
  String get gross => 'Gross';

  @override
  String get deductions => 'Deductions (₹)';

  @override
  String get deductionsHint => 'Moisture cut, commission, hamali, transport';

  @override
  String get deductionNote => 'What were the deductions?';

  @override
  String get net => 'Net';

  @override
  String get receivedNow => 'Received now (₹)';

  @override
  String get received => 'Received';

  @override
  String get pending => 'Pending';

  @override
  String get fullyPaid => 'Fully paid';

  @override
  String get updateReceived => 'Update received';

  @override
  String moreThanLeft(String kg) {
    return 'Only $kg kg left';
  }

  @override
  String get enterSomethingSold => 'Enter the kg sold for at least one grade';

  @override
  String get deleteSale => 'Delete sale';

  @override
  String get lotCost => 'Harvest + processing cost';

  @override
  String get saleValue => 'Sale value';

  @override
  String get profit => 'Profit';

  @override
  String get costPerKg => 'Cost per kg of chali';

  @override
  String get deleteLot => 'Delete lot';

  @override
  String get deleteLotBody =>
      'Deletes this lot with its labour, grades and sales. Workers\' accounts are corrected.';

  @override
  String get eventCover => 'Covered for rain';

  @override
  String get eventTurn => 'Turned';

  @override
  String get eventMoisture => 'Moisture check';

  @override
  String get eventPest => 'Pest check';

  @override
  String get eventNote => 'Note';

  @override
  String get removeLabourLine =>
      'Remove this labour entry? It is also removed from the worker\'s account.';

  @override
  String get labourTitle => 'Labour';

  @override
  String get tabWorkers => 'Workers';

  @override
  String get tabAttendance => 'Attendance';

  @override
  String get tabDues => 'Dues';

  @override
  String get addWorker => 'Add worker';

  @override
  String get noWorkers =>
      'No workers yet. Add the people who work in your garden.';

  @override
  String get roleClimber => 'Climber';

  @override
  String get roleSprayer => 'Sprayer';

  @override
  String get rolePeeler => 'Areca peeler';

  @override
  String get roleDaily => 'Daily labour';

  @override
  String get rolePlucker => 'Coconut plucker';

  @override
  String get due => 'Due';

  @override
  String get settled => 'Settled';

  @override
  String advanceHeld(String amount) {
    return 'Advance $amount';
  }

  @override
  String get inactive => 'No longer working';

  @override
  String presentCount(int n) {
    return '$n present';
  }

  @override
  String get wages => 'Wages';

  @override
  String get saveAttendance => 'Save attendance';

  @override
  String get present => 'Present';

  @override
  String get half => 'Half';

  @override
  String get absent => 'Absent';

  @override
  String get workToday => 'Work done';

  @override
  String get workHint => 'e.g. Fertiliser · Upper plot';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get noDayRate => 'No day rate set';

  @override
  String get totalDue => 'Total due to workers';

  @override
  String get pay => 'Pay';

  @override
  String get nobodyDue => 'Nobody is owed anything.';

  @override
  String get earned => 'Earned';

  @override
  String get paidAdvance => 'Paid + advance';

  @override
  String get ledger => 'Work & payments';

  @override
  String get payment => 'Payment';

  @override
  String get advance => 'Advance';

  @override
  String get kindWork => 'Work';

  @override
  String get kindPayment => 'Paid';

  @override
  String get kindAdvance => 'Advance';

  @override
  String get modeCash => 'Cash';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeBank => 'Bank';

  @override
  String balanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String get noLedger => 'Nothing recorded yet';

  @override
  String get deleteEntry => 'Delete this entry?';

  @override
  String get workEntryLocked =>
      'Work entries change from the attendance or the lot they came from.';

  @override
  String get workerName => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get roles => 'Roles';

  @override
  String get dayRate => 'Day rate (₹)';

  @override
  String get halfDayRate => 'Half-day rate (₹)';

  @override
  String get halfDayHint => 'Leave empty for half the day rate';

  @override
  String get pieceRate => 'Piece rate (₹)';

  @override
  String get pieceUnit => 'Per';

  @override
  String get activeWorker => 'Still working with us';

  @override
  String get editWorker => 'Edit worker';

  @override
  String get amountRupees => 'Amount (₹)';

  @override
  String get paidBy => 'Paid by';

  @override
  String perUnit(String rate, String unit) {
    return '$rate / $unit';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get farm => 'Farm';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get kannada => 'ಕನ್ನಡ';

  @override
  String get exportDb => 'Export database';

  @override
  String get exportDbSub => 'Save a safety copy to Google Drive or WhatsApp';

  @override
  String exportFailed(String error) {
    return 'Could not export: $error';
  }

  @override
  String get dataOnPhone =>
      'All data is stored on this phone. Cloud backup comes in the next update.';

  @override
  String get comingNext =>
      'Your farm records stay on this phone. Export a backup regularly.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get xDiary => 'Farm diary';

  @override
  String get xStock => 'Inputs & stock';

  @override
  String get xSales => 'Sales & buyers';

  @override
  String get xExpenses => 'Expenses';

  @override
  String get xReports => 'Reports';

  @override
  String get xLand => 'Land parcels';

  @override
  String get xLoans => 'Loans';

  @override
  String get xInsurance => 'Insurance & schemes';

  @override
  String get xDocuments => 'Documents';

  @override
  String get xReminders => 'Reminders';

  @override
  String get xPrices => 'Market prices';

  @override
  String get xWeather => 'Weather & rain';

  @override
  String get xCalendar => 'Calendar';

  @override
  String get xBackup => 'Backup & restore';

  @override
  String get xSecurity => 'App lock';

  @override
  String get xCropDetails => 'Crop details';

  @override
  String get xTitle => 'Title';

  @override
  String get xSearch => 'Search';

  @override
  String get xAll => 'All';

  @override
  String get xEmpty => 'No records yet. Add your first entry.';

  @override
  String get xType => 'Type';

  @override
  String get xQuantity => 'Quantity';

  @override
  String get xUnit => 'Unit';

  @override
  String get xRate => 'Rate';

  @override
  String get xAmount => 'Amount';

  @override
  String get xWorker => 'Worker';

  @override
  String get xCrop => 'Crop';

  @override
  String get xPlot => 'Plot';

  @override
  String get xDays => 'Days';

  @override
  String get xFrom => 'From';

  @override
  String get xTo => 'To';

  @override
  String get xStatus => 'Status';

  @override
  String get xDone => 'Done';

  @override
  String get xPending => 'Pending';

  @override
  String get xClose => 'Close';

  @override
  String get xContinue => 'Continue';

  @override
  String get xChoose => 'Choose';

  @override
  String get xNoSelection => 'None';

  @override
  String get xError => 'Could not save. Check the values and try again.';

  @override
  String get xPositive => 'Enter a value greater than zero';

  @override
  String get xInvalid => 'Check this value';

  @override
  String get xActivity => 'Add work';

  @override
  String get xFertiliser => 'Fertiliser';

  @override
  String get xSpray => 'Spray';

  @override
  String get xIrrigation => 'Irrigation';

  @override
  String get xWeeding => 'Weeding';

  @override
  String get xMulching => 'Mulching';

  @override
  String get xCropCare => 'Crop care';

  @override
  String get xOther => 'Other';

  @override
  String get xInputsUsed => 'Inputs used';

  @override
  String get xAddInput => 'Add input';

  @override
  String get xAddLabour => 'Add labour';

  @override
  String get xRemindOn => 'Remind me on';

  @override
  String get xAddReminder => 'Add reminder';

  @override
  String get xPhoto => 'Add photo';

  @override
  String get xVoice => 'Dictate note';

  @override
  String get xListening => 'Listening… tap to stop';

  @override
  String get xVoiceUnavailable =>
      'Speech recognition is unavailable. Check the phone language and microphone permission.';

  @override
  String get xStockName => 'Product name';

  @override
  String get xMinimum => 'Low-stock level';

  @override
  String get xPurchase => 'Record purchase';

  @override
  String get xSupplier => 'Shop / supplier';

  @override
  String get xAvailable => 'Available';

  @override
  String get xValue => 'Value';

  @override
  String get xLowStock => 'Low stock';

  @override
  String get xAverageCost => 'Average purchase cost';

  @override
  String get xStockHint =>
      'Stock is valued at moving average purchase cost. Diary usage reduces stock and books the cost once.';

  @override
  String get xCategory => 'Category';

  @override
  String get xElectricity => 'Electricity';

  @override
  String get xDiesel => 'Diesel';

  @override
  String get xRepairs => 'Repairs';

  @override
  String get xTools => 'Tools';

  @override
  String get xTransport => 'Transport';

  @override
  String get xIncome => 'Income';

  @override
  String get xCosts => 'Costs';

  @override
  String get xProfit => 'Profit / loss';

  @override
  String get xSeason => 'Season';

  @override
  String get xPreviousSeason => 'Previous season';

  @override
  String get xLabourCost => 'Labour cost';

  @override
  String get xInputCost => 'Inputs consumed';

  @override
  String get xInterestPaid => 'Interest paid';

  @override
  String get xPremiums => 'Insurance premiums';

  @override
  String get xExportPdf => 'Share PDF';

  @override
  String get xExportExcel => 'Share Excel';

  @override
  String get xShareStatement => 'Share statement';

  @override
  String get xReportBasis =>
      'Accrual report: sales less wages earned, inputs consumed, expenses, interest paid and premiums. Stock purchases and wage payments are not counted twice.';

  @override
  String get xSurvey => 'Survey number';

  @override
  String get xHissa => 'Hissa';

  @override
  String get xLender => 'Lender';

  @override
  String get xLenderKind => 'Lender type';

  @override
  String get xBank => 'Bank';

  @override
  String get xSociety => 'Society / PACS';

  @override
  String get xPrivate => 'Private lender';

  @override
  String get xLoanKind => 'Loan type';

  @override
  String get xCropLoan => 'Crop / KCC';

  @override
  String get xTermLoan => 'Term loan';

  @override
  String get xGoldLoan => 'Gold loan';

  @override
  String get xHandLoan => 'Hand loan';

  @override
  String get xSanctioned => 'Sanctioned limit';

  @override
  String get xAnnualRate => 'Annual interest %';

  @override
  String get xSimple => 'Simple interest';

  @override
  String get xCompound => 'Compound interest';

  @override
  String get xCompounding => 'Compounding interval (months)';

  @override
  String get xTenure => 'Tenure (months)';

  @override
  String get xSecurityLand => 'Land given as security';

  @override
  String get xOutstanding => 'Outstanding principal';

  @override
  String get xAccruedInterest => 'Estimated accrued interest';

  @override
  String get xWithdrawal => 'Withdrawal';

  @override
  String get xPrincipalPayment => 'Principal repayment';

  @override
  String get xInterestPayment => 'Interest payment';

  @override
  String get xCharge => 'Charge';

  @override
  String get xAddTransaction => 'Add transaction';

  @override
  String get xLoanEstimate =>
      'Estimate uses actual days / 365. Enter principal and interest payments separately. Verify against the lender statement.';

  @override
  String get xConcession => 'Timely payment keeps a lower interest rate';

  @override
  String get xActive => 'Active';

  @override
  String get xClosed => 'Closed';

  @override
  String get xMembership => 'Society memberships';

  @override
  String get xMemberNumber => 'Member number';

  @override
  String get xOrganization => 'Organization';

  @override
  String get xShares => 'Shares';

  @override
  String get xShareValue => 'Value per share';

  @override
  String get xDividend => 'Dividend';

  @override
  String get xSharePurchase => 'Share purchase';

  @override
  String get xPolicies => 'Policies';

  @override
  String get xClaims => 'Claims';

  @override
  String get xSchemes => 'Schemes / subsidies';

  @override
  String get xScheme => 'Scheme name';

  @override
  String get xPolicyNumber => 'Policy / application number';

  @override
  String get xPremium => 'Premium paid';

  @override
  String get xEnrolBy => 'Enrolment deadline';

  @override
  String get xLossDate => 'Date of loss';

  @override
  String get xFiledDate => 'Claim filed on';

  @override
  String get xClaimed => 'Amount claimed';

  @override
  String get xReceived => 'Amount received';

  @override
  String get xReceivedOn => 'Received on';

  @override
  String get xDepartment => 'Department';

  @override
  String get xAppliedOn => 'Applied on';

  @override
  String get xApplicationNumber => 'Application number';

  @override
  String get xSubsidy => 'Subsidy amount';

  @override
  String get xDraft => 'Draft';

  @override
  String get xFiled => 'Filed';

  @override
  String get xApproved => 'Approved';

  @override
  String get xRejected => 'Rejected';

  @override
  String get xPaid => 'Paid';

  @override
  String get xExpired => 'Expired';

  @override
  String get xAddDocument => 'Add document';

  @override
  String get xOpen => 'Open';

  @override
  String get xCamera => 'Camera';

  @override
  String get xGallery => 'Gallery';

  @override
  String get xFile => 'File';

  @override
  String get xDocumentKind => 'Document type';

  @override
  String get xRtc => 'RTC / land record';

  @override
  String get xBill => 'Bill';

  @override
  String get xPolicy => 'Policy';

  @override
  String get xDueOn => 'Due on';

  @override
  String get xMillimetres => 'Rainfall (mm)';

  @override
  String get xMarket => 'Market';

  @override
  String get xSource => 'Source';

  @override
  String get xGrade => 'Grade / product';

  @override
  String get xMinPrice => 'Minimum price';

  @override
  String get xMaxPrice => 'Maximum price';

  @override
  String get xModalPrice => 'Typical / modal price';

  @override
  String get xPricePerKg => '₹ per kg (nuts / bunches per unit)';

  @override
  String get xPriceAlert => 'Price alerts';

  @override
  String get xTarget => 'Target price';

  @override
  String get xAbove => 'At or above';

  @override
  String get xBelow => 'At or below';

  @override
  String get xHistory => 'History';

  @override
  String get xRefresh => 'Refresh';

  @override
  String get xLastUpdated => 'Last updated';

  @override
  String get xOffline => 'Offline / saved data';

  @override
  String get xNoWeather => 'Set the farm location to download a forecast.';

  @override
  String get xLatitude => 'Latitude';

  @override
  String get xLongitude => 'Longitude';

  @override
  String get xUseLocation => 'Use phone location';

  @override
  String get xLocation => 'Farm location';

  @override
  String get xForecast => 'Seven-day forecast';

  @override
  String get xRainChance => 'Rain chance';

  @override
  String get xRainLog => 'Rain gauge log';

  @override
  String get xRainWarning => 'Rain expected: cover drying lots';

  @override
  String get xVariety => 'Variety';

  @override
  String get xPlantedOn => 'Planting date';

  @override
  String get xBearing => 'Bearing crop';

  @override
  String get xRatoon => 'Ratoon number';

  @override
  String get xTrailedOn => 'Trailed on which palms';

  @override
  String get xCount => 'Count';

  @override
  String get xProduce => 'Coconut, pepper & banana';

  @override
  String get xProduct => 'Product';

  @override
  String get xNuts => 'Nuts';

  @override
  String get xBunches => 'Bunches';

  @override
  String get xCopra => 'Copra';

  @override
  String get xThreshing => 'Threshing';

  @override
  String get xDehusking => 'Dehusking';

  @override
  String get xFinishProcessing => 'Record finished quantity';

  @override
  String get xFinishedQuantity => 'Finished quantity';

  @override
  String get xStorage => 'Storage';

  @override
  String get xPlace => 'Place';

  @override
  String get xBags => 'Bags';

  @override
  String get xHarvestQuantity => 'Harvest quantity';

  @override
  String get xRecordSale => 'Record sale';

  @override
  String get xRecordPayment => 'Record buyer payment';

  @override
  String get xBuyer => 'Buyer';

  @override
  String get xDeductions => 'Deductions';

  @override
  String get xBalance => 'Balance';

  @override
  String get xStartDrying => 'Start drying';

  @override
  String get xFinishDrying => 'Finish drying';

  @override
  String get xRestore => 'Restore backup';

  @override
  String get xCreateBackup => 'Create backup';

  @override
  String get xRestoreWarning =>
      'This replaces the app records with the selected backup. A safety backup is created first. Continue?';

  @override
  String get xBackupHint =>
      'Includes the database, photos and documents. Keep a copy outside this phone.';

  @override
  String get xLockEnabled => 'Require phone PIN or fingerprint';

  @override
  String get xUnlock => 'Unlock Dhara Mitra';

  @override
  String get xAuthenticationFailed => 'Authentication was not completed';

  @override
  String get xEnableNotifications => 'Enable reminders';

  @override
  String get xCloudSetup => 'Cloud setup';

  @override
  String get xCloudNotConfigured =>
      'Cloud backup and automatic market feeds need account setup. Local records, manual prices and backups work now.';

  @override
  String get xSaveFailed => 'Not saved';

  @override
  String get xInterestMethod => 'Interest method';

  @override
  String get xTransactions => 'Transactions';

  @override
  String get xWeatherSource => 'Forecast: Open-Meteo. Forecasts are estimates.';

  @override
  String get xLoanDues => 'Upcoming loan dues';

  @override
  String get xSpentMonth => 'Spent this month';

  @override
  String get xPerAcre => 'Profit per acre';

  @override
  String get xYield => 'Yield';

  @override
  String get xOutTurn => 'Dry out-turn';

  @override
  String get xDeleteBlocked =>
      'This record is used by other records. Remove those links first.';

  @override
  String get xAmountTooLarge => 'Amount exceeds the balance';

  @override
  String get xNotEnoughStock => 'Quantity exceeds available stock';

  @override
  String get xCannotReduceSold =>
      'Cannot reduce a grade below the quantity already sold';

  @override
  String get xCheckDates => 'Check the order of the dates';

  @override
  String get xOverdue => 'Overdue';

  @override
  String get xDays7 => '7 days';

  @override
  String get xDays30 => '30 days';

  @override
  String get xYear => '1 year';

  @override
  String get xPhotoSaved => 'Photo saved';

  @override
  String get xNoLiveFeed =>
      'Manual price entry works offline. Automatic feeds need cloud setup.';

  @override
  String get xLabourShare => 'Labour share of costs';

  @override
  String get xApplied => 'Applied';

  @override
  String get xBackupInvalid =>
      'Backup is invalid or incomplete. Use a full Dhara Mitra ZIP backup including its attachments.';

  @override
  String get xPerPalm => 'Chali kg per palm';

  @override
  String get xAllocation =>
      'Shared records are split equally between their selected crops and plots. Unassigned costs appear in the whole-farm report.';

  @override
  String get xAttendanceUsed =>
      'This attendance is absent or its daily wage is already fully allocated. Check attendance and split shared days between jobs; record extra piecework separately.';

  @override
  String get fChooseLocation => 'Choose farm on map';

  @override
  String get fMapHint =>
      'Tap your farm to place a pin. Zoom in to move it precisely.';

  @override
  String get fMapOffline =>
      'Map needs internet. You can go back and add the location later.';

  @override
  String get fLocationUnavailable =>
      'Could not find your location. Tap the map instead.';

  @override
  String get fUsePin => 'Use this location';

  @override
  String get fLocationSaved => 'Farm location selected';

  @override
  String get fLocationOptional =>
      'Optional. Choose your farm for local weather; you can add it later.';

  @override
  String get fMobileError => 'Enter a valid 10-digit Indian mobile number';

  @override
  String get fTelephone => 'Landline with STD code (optional)';

  @override
  String get fTelephoneError => 'Enter a valid Indian landline with STD code';

  @override
  String get fCall => 'Call';

  @override
  String get fCallUnavailable =>
      'Could not open the dialler. Check the number.';

  @override
  String get fAddRole => 'Add role';

  @override
  String get fRoleHint => 'For example: irrigation, tractor driver';

  @override
  String get fApplyAll => 'Apply this work to everyone';

  @override
  String get fCollections => 'Collected from farm';

  @override
  String get fCollectionHint =>
      'Record each pickup. Select one or more pickups when you are ready to dry them.';

  @override
  String get fNewCollection => 'Add collection';

  @override
  String get fDrySelected => 'Dry selected together';

  @override
  String get fUnassigned => 'Waiting for drying';

  @override
  String get fAssigned => 'In drying lot';

  @override
  String get fBagsMode => 'Bags until peeling';

  @override
  String get fKgMode => 'Kilograms throughout';

  @override
  String get fQuantityMode => 'How do you measure your harvest?';

  @override
  String get fFreshBags => 'Bags collected';

  @override
  String get fDriedBags => 'Dried bags brought home';

  @override
  String get fQuantityUnknown => 'Not measured yet';

  @override
  String get fMixedUnits =>
      'Choose collections with the same unit. Bags and kg cannot be added together.';

  @override
  String get fCollectionLocked =>
      'This collection is already in a lot. Open the lot to view it.';

  @override
  String get fCollectionDateError =>
      'Drying cannot start before the latest collection date.';

  @override
  String get fFertilizer => 'Fertilizer';

  @override
  String get fFarms => 'My farms';

  @override
  String get fAddFarm => 'Add farm';

  @override
  String get fDeleteFarm => 'Delete farm';

  @override
  String get fDeleteFarmBody =>
      'Delete this farm and all its records and attached files from this device? This cannot be undone. Exported backups will remain.';

  @override
  String get fFarmSeparate =>
      'Each farm has its own workers, accounts and records. Switch farms before entering work.';

  @override
  String get fFarmBackup =>
      'This backup contains the selected farm. Back up each farm separately.';

  @override
  String get fBackupAll => 'Back up all farms';

  @override
  String get fImportFarms => 'Import farms from backup';

  @override
  String get fImportHint =>
      'Adds farms as new profiles. Your current farms are kept unchanged.';

  @override
  String get fImported => 'Farms imported. Open My farms to choose one.';

  @override
  String get wOpeningShares => 'Opening shares';

  @override
  String get wTransactionHint => 'Tap a transaction to edit; hold to remove.';

  @override
  String get wDailyHint =>
      'Daily work reuses attendance wages. Enter 0.5 for half a day. Split a shared day between jobs; record extra piecework separately. Existing attendance rates apply.';

  @override
  String get nFarmTools => 'Farm tools';
}
