import '../../core/v1.dart';
import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/season.dart';
import '../../core/validation.dart';
import '../common/feature_providers.dart';
import '../common/forms.dart';
import '../common/labels.dart';
import '../common/record_page.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  Future<void> edit(
    BuildContext context,
    WidgetRef ref, [
    Expense? expense,
  ]) async {
    final l = context.l;
    final plots = ref.read(plotsProvider).value ?? [];
    final lots=ref.read(lotViewsProvider).value ?? [];
    final produce=ref.read(produceProvider).value ?? [];
    await openEntryForm(
      context,
      title: l.xExpenses,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: expense?.date ?? ref.read(entryDayProvider),
        ),
        EntryField(
          'category',
          l.xCategory,
          kind: InputKind.choice,
          required: true,
          initial: expense?.category ?? 'other',
          options: {
            for (final k in [
              'materials',
              'externalLabour',
              'electricity',
              'diesel',
              'repairs',
              'tools',
              'transport',
              'other',
            ])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'amount',
          l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: expense == null ? null : paiseToInput(expense.amount),
        ),
        EntryField(
          'crop',
          l.xCrop,
          kind: InputKind.choice,
          initial: expense?.crop ?? '',
          options: {'': l.xAll, ...cropOptions(context)},
        ),
        EntryField(
          'plot',
          l.xPlot,
          kind: InputKind.choice,
          initial: expense?.plotId ?? '',
          options: {'': l.xAll, for (final p in plots) p.id: p.name},
        ),
        EntryField(
          'notes',
          l.notes,
          kind: InputKind.notes,
          initial: expense?.notes,
        ),
        EntryField('lot',l.lotsTitle,kind:InputKind.choice,
          initial:expense?.lotId != null ? 'areca:${expense!.lotId}' : expense?.produceLotId != null ? 'produce:${expense!.produceLotId}' : '',
          options:{'':l.xNoSelection,for(final lot in lots) 'areca:${lot.lot.id}':lot.lot.code,for(final lot in produce) 'produce:${lot.lot.id}':lot.lot.code}),
      ],
      onSave: (v) => ref
          .read(financeRepositoryProvider)
          .expense(
            id: expense?.id,
            date: v.date('date'),
            category: v.text('category'),
            amount: v.money('amount'),
            crop: v.text('crop').isEmpty ? null : v.text('crop'),
            plotId: v.text('plot').isEmpty ? null : v.text('plot'),
            notes: v.text('notes'),
            lotId:v.text('lot').startsWith('areca:') ? v.text('lot').substring(6) : null,
            produceLotId:v.text('lot').startsWith('produce:') ? v.text('lot').substring(8) : null,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => RecordPage(
    title: context.l.xExpenses,
    intro: v1Text(context, 'Worker wages are counted from attendance and work. Record worker payments under Workers; do not enter them again here.', 'ಕಾರ್ಮಿಕರ ವೇತನ ಹಾಜರಿ ಮತ್ತು ಕೆಲಸದಿಂದ ಲೆಕ್ಕವಾಗುತ್ತದೆ. ಪಾವತಿಯನ್ನು ಕಾರ್ಮಿಕರ ವಿಭಾಗದಲ್ಲಿ ದಾಖಲಿಸಿ; ಇಲ್ಲಿ ಮತ್ತೆ ಸೇರಿಸಬೇಡಿ.'),
    value: ref.watch(expensesProvider),
    onAdd: () => edit(context, ref),
    itemBuilder: (Expense e) => RecordItem(
      id: e.id,
      title: recordLabel(context, e.category),
      subtitle: '${context.fmt.date(e.date)} · ${context.fmt.money(e.amount)}',
      refType: 'expense',
      details: {
        context.l.notes: e.notes,
        context.l.xCrop: e.crop == null
            ? context.l.xAll
            : recordLabel(context, e.crop!),
      },
      onEdit: () => edit(context, ref, e),
      onDelete: () => ref.read(financeRepositoryProvider).deleteExpense(e.id),
    ),
  );
}

class LandScreen extends ConsumerWidget {
  const LandScreen({super.key});
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    LandParcel? parcel,
  ]) async {
    final l = context.l;
    final plots = ref.read(plotsProvider).value ?? [];
    final area = toAcresGuntas(parcel?.acres ?? 0);
    await openEntryForm(
      context,
      title: l.xLand,
      fields: [
        EntryField(
          'survey',
          l.xSurvey,
          required: true,
          initial: parcel?.surveyNumber,
        ),
        EntryField('hissa', l.xHissa, initial: parcel?.hissa),
        EntryField('village', l.village, initial: parcel?.village),
        EntryField('acres', l.acres, kind: InputKind.integer, initial: area.$1),
        EntryField(
          'guntas',
          Localizations.localeOf(context).languageCode == 'kn'
              ? 'ಗುಂಟೆ'
              : 'Guntas',
          kind: InputKind.integer,
          initial: area.$2,
          maximum: 39,
        ),
        EntryField(
          'plots',
          l.plotsTitle,
          kind: InputKind.multiple,
          initial: parcel?.plotIds.toSet(),
          options: {for (final p in plots) p.id: p.name},
        ),
        EntryField(
          'notes',
          l.notes,
          kind: InputKind.notes,
          initial: parcel?.notes,
        ),
      ],
      onSave: (v) async {
        await ref
            .read(financeRepositoryProvider)
            .parcel(
              id: parcel?.id,
              survey: v.text('survey'),
              hissa: v.text('hissa'),
              village: v.text('village'),
              acres: v.number('acres') + v.number('guntas') / 40,
              plotIds: v.selected('plots'),
              notes: v.text('notes'),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => RecordPage(
    title: context.l.xLand,
    value: ref.watch(parcelsProvider),
    onAdd: () => _edit(context, ref),
    itemBuilder: (LandParcel p) => RecordItem(
      id: p.id,
      title: '${p.surveyNumber}${p.hissa.isEmpty ? '' : '/${p.hissa}'}',
      subtitle: '${p.village} · ${context.fmt.area(p.acres)}',
      refType: 'land',
      details: {context.l.notes: p.notes},
      onEdit: () => _edit(context, ref, p),
      onDelete: () async {
        final db = ref.read(databaseProvider);
        final loans =
            await (db.select(db.loans)..where(
                  (l) => l.parcelId.equals(p.id) & l.deleted.equals(false),
                ))
                .get();
        if (loans.isNotEmpty) throw const FarmException('linked');
        await (db.update(
          db.landParcels,
        )..where((l) => l.id.equals(p.id))).write(
          LandParcelsCompanion(
            deleted: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
      },
    ),
  );
}

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});
  Future<void> _policy(
    BuildContext context,
    WidgetRef ref, [
    InsurancePolicy? policy,
  ]) async {
    final l = context.l;
    final today = ref.read(todayProvider);
    final farm = ref.read(farmProvider).value;
    await openEntryForm(
      context,
      title: l.xPolicy,
      fields: [
        EntryField(
          'scheme',
          l.xScheme,
          required: true,
          initial: policy?.scheme,
        ),
        EntryField(
          'crop',
          l.xCrop,
          kind: InputKind.choice,
          required: true,
          initial: policy?.crop ?? 'areca',
          options: cropOptions(context),
        ),
        EntryField(
          'season',
          l.xSeason,
          kind: InputKind.integer,
          required: true,
          minimum: 2000,
          maximum: 2100,
          initial:
              policy?.seasonStartYear ??
              Season.of(
                today,
                startMonth: farm?.seasonStartMonth ?? 6,
              ).startYear,
        ),
        EntryField(
          'acres',
          l.acres,
          kind: InputKind.quantity,
          required: true,
          positive: true,
          initial: policy?.acres,
        ),
        EntryField(
          'premium',
          l.xPremium,
          kind: InputKind.money,
          required: true,
          initial: policy == null ? null : paiseToInput(policy.premium),
        ),
        EntryField(
          'paidOn',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: policy?.paidOn ?? today,
        ),
        EntryField(
          'number',
          l.xPolicyNumber,
          required: true,
          initial: policy?.policyNumber,
        ),
        EntryField(
          'deadline',
          l.xEnrolBy,
          kind: InputKind.date,
          initial: policy?.enrolBy,
        ),
        EntryField(
          'status',
          l.xStatus,
          kind: InputKind.choice,
          required: true,
          initial: policy?.status ?? 'active',
          options: {
            for (final k in ['active', 'expired', 'closed'])
              k: recordLabel(context, k),
          },
        ),
      ],
      onSave: (v) async {
        await ref
            .read(financeRepositoryProvider)
            .policy(
              id: policy?.id,
              scheme: v.text('scheme'),
              crop: v.text('crop'),
              season: v.integer('season'),
              acres: v.number('acres'),
              premium: v.money('premium'),
              paidOn: v.date('paidOn'),
              number: v.text('number'),
              enrolBy: v.optionalDate('deadline'),
              status: v.text('status'),
            );
      },
    );
  }

  Future<void> _claim(
    BuildContext context,
    WidgetRef ref, [
    InsuranceClaim? claim,
  ]) async {
    final l = context.l;
    final policies = ref.read(policiesProvider).value ?? [];
    await openEntryForm(
      context,
      title: l.xClaims,
      fields: [
        EntryField(
          'policy',
          l.xPolicy,
          kind: InputKind.choice,
          required: true,
          initial: claim?.policyId,
          options: {
            for (final p in policies) p.id: '${p.scheme} · ${p.policyNumber}',
          },
        ),
        EntryField(
          'loss',
          l.xLossDate,
          kind: InputKind.date,
          required: true,
          initial: claim?.lossOn ?? ref.read(todayProvider),
        ),
        EntryField(
          'filed',
          l.xFiledDate,
          kind: InputKind.date,
          initial: claim?.filedOn,
        ),
        EntryField(
          'claimed',
          l.xClaimed,
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: claim == null ? null : paiseToInput(claim.claimed),
        ),
        EntryField(
          'received',
          l.xReceived,
          kind: InputKind.money,
          initial: claim == null ? null : paiseToInput(claim.received),
        ),
        EntryField(
          'receivedOn',
          l.xReceivedOn,
          kind: InputKind.date,
          initial: claim?.receivedOn,
        ),
        EntryField(
          'status',
          l.xStatus,
          kind: InputKind.choice,
          required: true,
          initial: claim?.status ?? 'draft',
          options: {
            for (final k in ['draft', 'filed', 'approved', 'rejected', 'paid'])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'notes',
          l.notes,
          kind: InputKind.notes,
          initial: claim?.notes,
        ),
      ],
      onSave: (v) => ref
          .read(financeRepositoryProvider)
          .claim(
            id: claim?.id,
            policyId: v.text('policy'),
            lossOn: v.date('loss'),
            filedOn: v.optionalDate('filed'),
            claimed: v.money('claimed'),
            received: v.money('received'),
            receivedOn: v.optionalDate('receivedOn'),
            status: v.text('status'),
            notes: v.text('notes'),
          ),
    );
  }

  Future<void> _scheme(
    BuildContext context,
    WidgetRef ref, [
    SchemeApplication? scheme,
  ]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xSchemes,
      fields: [
        EntryField(
          'scheme',
          l.xScheme,
          required: true,
          initial: scheme?.scheme,
        ),
        EntryField(
          'department',
          l.xDepartment,
          required: true,
          initial: scheme?.department,
        ),
        EntryField(
          'applied',
          l.xAppliedOn,
          kind: InputKind.date,
          required: true,
          initial: scheme?.appliedOn ?? ref.read(todayProvider),
        ),
        EntryField(
          'number',
          l.xApplicationNumber,
          initial: scheme?.applicationNumber,
        ),
        EntryField(
          'status',
          l.xStatus,
          kind: InputKind.choice,
          required: true,
          initial: scheme?.status ?? 'applied',
          options: {
            for (final k in ['applied', 'approved', 'rejected', 'paid'])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'subsidy',
          l.xSubsidy,
          kind: InputKind.money,
          initial: scheme == null ? null : paiseToInput(scheme.subsidy),
        ),
        EntryField(
          'receivedOn',
          l.xReceivedOn,
          kind: InputKind.date,
          initial: scheme?.receivedOn,
        ),
        EntryField(
          'notes',
          l.notes,
          kind: InputKind.notes,
          initial: scheme?.notes,
        ),
      ],
      onSave: (v) => ref
          .read(financeRepositoryProvider)
          .scheme(
            id: scheme?.id,
            scheme: v.text('scheme'),
            department: v.text('department'),
            appliedOn: v.date('applied'),
            number: v.text('number'),
            status: v.text('status'),
            subsidy: v.money('subsidy'),
            receivedOn: v.optionalDate('receivedOn'),
            notes: v.text('notes'),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.xInsurance),
          bottom: TabBar(
            tabs: [
              Tab(text: l.xPolicies),
              Tab(text: l.xClaims),
              Tab(text: l.xSchemes),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RecordPage(
              title: l.xPolicies,
              embedded: true,
              value: ref.watch(policiesProvider),
              onAdd: () => _policy(context, ref),
              itemBuilder: (InsurancePolicy p) => RecordItem(
                id: p.id,
                title: p.scheme,
                subtitle:
                    '${p.policyNumber} · ${recordLabel(context, p.status)}',
                refType: 'policy',
                details: {
                  l.xCrop: recordLabel(context, p.crop),
                  l.xSeason: '${p.seasonStartYear}–${p.seasonStartYear + 1}',
                  l.acres: formatQty(p.acres),
                  l.xPremium: context.fmt.money(p.premium),
                  if (p.enrolBy != null)
                    l.xEnrolBy: context.fmt.date(p.enrolBy!),
                },
                onEdit: () => _policy(context, ref, p),
              ),
            ),
            RecordPage(
              title: l.xClaims,
              embedded: true,
              value: ref.watch(claimsProvider),
              onAdd: () => _claim(context, ref),
              itemBuilder: (InsuranceClaim c) => RecordItem(
                id: c.id,
                title:
                    ref
                        .watch(policiesProvider)
                        .value
                        ?.where((p) => p.id == c.policyId)
                        .firstOrNull
                        ?.scheme ??
                    l.xClaims,
                subtitle:
                    '${context.fmt.date(c.lossOn)} · ${recordLabel(context, c.status)}',
                refType: 'claim',
                details: {
                  l.xClaimed: context.fmt.money(c.claimed),
                  l.xReceived: context.fmt.money(c.received),
                  l.notes: c.notes,
                },
                onEdit: () => _claim(context, ref, c),
              ),
            ),
            RecordPage(
              title: l.xSchemes,
              embedded: true,
              value: ref.watch(schemesProvider),
              onAdd: () => _scheme(context, ref),
              itemBuilder: (SchemeApplication s) => RecordItem(
                id: s.id,
                title: s.scheme,
                subtitle: '${s.department} · ${recordLabel(context, s.status)}',
                refType: 'scheme',
                details: {
                  l.xApplicationNumber: s.applicationNumber,
                  l.xSubsidy: context.fmt.money(s.subsidy),
                  l.xAppliedOn: context.fmt.date(s.appliedOn),
                  if (s.receivedOn != null)
                    l.xReceivedOn: context.fmt.date(s.receivedOn!),
                  l.notes: s.notes,
                },
                onEdit: () => _scheme(context, ref, s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
