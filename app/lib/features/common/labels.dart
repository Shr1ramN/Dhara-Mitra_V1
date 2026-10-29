import '../../core/v1.dart';
import 'package:flutter/widgets.dart';

import '../../core/enums.dart';
import '../../core/l10n.dart';

Map<String, String> cropOptions(BuildContext context) => {
  for (final crop in Crop.values) crop.name: context.l.crop(crop),
};
Map<String, String> statusOptions(BuildContext context) => {
  'active': context.l.xActive,
  'closed': context.l.xClosed,
  'draft': context.l.xDraft,
  'applied': context.l.xAppliedOn,
  'filed': context.l.xFiled,
  'approved': context.l.xApproved,
  'rejected': context.l.xRejected,
  'paid': context.l.xPaid,
  'expired': context.l.xExpired,
};
String recordLabel(BuildContext context, String key) =>
    {
      ...cropOptions(context),
      ...statusOptions(context),
      'simple': context.l.xSimple,
      'compound': context.l.xCompound,
      'withdrawal': context.l.xWithdrawal,
      'principal': context.l.xPrincipalPayment,
      'interest': context.l.xInterestPayment,
      'charge': context.l.xCharge,
      'materials': v1Text(context, 'Materials', 'ಸಾಮಗ್ರಿಗಳು'),
      'externalLabour': v1Text(context, 'Other labour (not worker wages)', 'ಇತರೆ ಕೂಲಿ (ಕಾರ್ಮಿಕರ ವೇತನವಲ್ಲ)'),
      'electricity': context.l.xElectricity,
      'diesel': context.l.xDiesel,
      'repairs': context.l.xRepairs,
      'tools': context.l.xTools,
      'transport': context.l.xTransport,
      'other': context.l.xOther,
      'kg': context.l.kgUnit,
      'nut': context.l.xNuts,
      'bunch': context.l.xBunches,
      'copra': context.l.xCopra,
      'harvest': context.l.navHarvest,
      'threshing': context.l.xThreshing,
      'drying': context.l.stageDrying,
      'dehusking': context.l.xDehusking,
      'storage': context.l.xStorage,
      'sold': context.l.stageSold,
      'bank': context.l.xBank,
      'society': context.l.xSociety,
      'campco': 'CAMPCO',
      'private': context.l.xPrivate,
      'crop_kcc': context.l.xCropLoan,
      'term': context.l.xTermLoan,
      'gold': context.l.xGoldLoan,
      'hand': context.l.xHandLoan,
      'dividend': context.l.xDividend,
      'share_purchase': context.l.xSharePurchase,
    }[key] ??
    key;
