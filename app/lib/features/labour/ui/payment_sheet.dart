import 'payroll_screens.dart';

import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';

/// Pay a worker or give an advance (F3.4, F3.5).
Future<void> showPaymentSheet(
  BuildContext context, {
  required Worker worker,
  required TxnKind kind,
  int? suggested,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => kind == TxnKind.advance
          ? WorkerLoanForm(worker: worker)
          : SettlementForm(worker: worker),
    ),
  );
}
