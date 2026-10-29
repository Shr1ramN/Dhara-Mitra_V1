import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'enums.dart';
import 'money.dart';
import 'quantity.dart';

export '../l10n/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);

  Formats get fmt => Formats(Localizations.localeOf(this).languageCode, l);
}

/// Locale-aware display of dates, money and weights.
class Formats {
  const Formats(this.locale, this.l);

  final String locale;
  final AppLocalizations l;

  String date(DateTime d) => DateFormat('d MMM y', locale).format(d);

  String dayMonth(DateTime d) => DateFormat('d MMM', locale).format(d);

  String weekdayDate(DateTime d) => DateFormat('EEE, d MMM', locale).format(d);

  String month(int month) =>
      DateFormat.MMMM(locale).format(DateTime(2000, month));

  String money(int paise) => formatRupees(paise);

  String moneyCompact(int paise) => formatMoneyCompact(paise, l.lakhUnit);

  String kg(num kg) => l.kgValue(formatQty(kg));

  String rate(int paise, RateUnit unit) =>
      l.perUnit(formatRupees(paise, showPaise: true), l.unit(unit));

  String percent(double value) => '${value.toStringAsFixed(1)}%';

  /// 2.7 → "2 acres 28 guntas" (F10.7).
  String area(double acres) {
    final (a, g) = toAcresGuntas(acres);
    return l.acresGuntas(a, g);
  }
}

extension EnumLabels on AppLocalizations {
  String crop(Crop c) => switch (c) {
    Crop.areca => cropAreca,
    Crop.coconut => cropCoconut,
    Crop.pepper => cropPepper,
    Crop.banana => cropBanana,
  };

  String stage(LotStage s) => switch (s) {
    LotStage.harvest => stageHarvest,
    LotStage.drying => stageDrying,
    LotStage.peeling => stagePeeling,
    LotStage.grading => stageGrading,
    LotStage.storage => stageStorage,
    LotStage.sold => stageSold,
  };

  String grade(ArecaGrade g) => switch (g) {
    ArecaGrade.chali => gradeChali,
    ArecaGrade.patora => gradePatora,
    ArecaGrade.ulliGadde => gradeUlliGadde,
    ArecaGrade.karigotu => gradeKarigotu,
    ArecaGrade.koka => gradeKoka,
  };

  String role(WorkerRole r) => switch (r) {
    WorkerRole.climber => roleClimber,
    WorkerRole.sprayer => roleSprayer,
    WorkerRole.peeler => rolePeeler,
    WorkerRole.daily => roleDaily,
    WorkerRole.plucker => rolePlucker,
  };

  String unit(RateUnit u) => switch (u) {
    RateUnit.day => unitDay,
    RateUnit.palm => unitPalm,
    RateUnit.tree => unitTree,
    RateUnit.kg => unitKg,
    RateUnit.nut => unitNut,
    RateUnit.lump => unitLump,
  };

  String irrigationType(Irrigation i) => switch (i) {
    Irrigation.sprinkler => irrSprinkler,
    Irrigation.drip => irrDrip,
    Irrigation.hose => irrHose,
    Irrigation.none => irrNone,
  };

  String buyerKind(BuyerKind k) => switch (k) {
    BuyerKind.campco => buyerCampco,
    BuyerKind.trader => buyerTrader,
    BuyerKind.apmc => buyerApmc,
    BuyerKind.other => buyerOther,
  };

  String payMode(PayMode m) => switch (m) {
    PayMode.cash => modeCash,
    PayMode.upi => modeUpi,
    PayMode.bank => modeBank,
  };

  String txnKind(TxnKind k) => switch (k) {
    TxnKind.work => kindWork,
    TxnKind.payment => kindPayment,
    TxnKind.advance => kindAdvance,
  };

  String eventKind(LotEventKind k) => switch (k) {
    LotEventKind.cover => eventCover,
    LotEventKind.turn => eventTurn,
    LotEventKind.moisture => eventMoisture,
    LotEventKind.pest => eventPest,
    LotEventKind.note => eventNote,
  };

  String attendance(AttendanceStatus s) => switch (s) {
    AttendanceStatus.present => present,
    AttendanceStatus.half => half,
    AttendanceStatus.absent => absent,
  };
}
