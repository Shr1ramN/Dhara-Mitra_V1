import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../common/feature_providers.dart';
import '../../common/forms.dart';
import '../../common/labels.dart';
import '../../common/record_page.dart';
import '../data/loans_repository.dart';
import '../data/memberships_repository.dart';
import '../../../core/quantity.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    final parcels = ref.read(parcelsProvider).value ?? [];
    await openEntryForm(
      context,
      title: l.xLoans,
      fields: [
        EntryField('lender', l.xLender, required: true),
        EntryField(
          'lenderKind',
          l.xLenderKind,
          kind: InputKind.choice,
          required: true,
          initial: 'society',
          options: {
            for (final k in ['society', 'bank', 'campco', 'private'])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'kind',
          l.xLoanKind,
          kind: InputKind.choice,
          required: true,
          initial: 'crop_kcc',
          options: {
            for (final k in ['crop_kcc', 'term', 'gold', 'hand'])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'limit',
          l.xSanctioned,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
        EntryField(
          'on',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(todayProvider),
        ),
        EntryField(
          'withdrawn',
          l.xWithdrawal,
          kind: InputKind.money,
          initial: '0',
        ),
        EntryField(
          'rate',
          l.xAnnualRate,
          kind: InputKind.quantity,
          required: true,
          maximum: 1000,
        ),
        EntryField(
          'method',
          l.xInterestMethod,
          kind: InputKind.choice,
          required: true,
          initial: 'simple',
          options: {'simple': l.xSimple, 'compound': l.xCompound},
        ),
        EntryField(
          'compound',
          l.xCompounding,
          kind: InputKind.choice,
          required: true,
          initial: '12',
          options: {'1': '1', '3': '3', '6': '6', '12': '12'},
        ),
        EntryField(
          'tenure',
          l.xTenure,
          kind: InputKind.integer,
          required: true,
          positive: true,
          maximum: 600,
          initial: 12,
        ),
        EntryField(
          'parcel',
          l.xSecurityLand,
          kind: InputKind.choice,
          initial: '',
          options: {
            '': l.xNoSelection,
            for (final p in parcels) p.id: '${p.surveyNumber} ${p.village}',
          },
        ),
        EntryField(
          'concession',
          l.xConcession,
          kind: InputKind.toggle,
          initial: false,
        ),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (v) async {
        await ref
            .read(loansRepositoryProvider)
            .create(
              lender: v.text('lender'),
              lenderKind: v.text('lenderKind'),
              kind: v.text('kind'),
              sanctioned: v.money('limit'),
              sanctionedOn: v.date('on'),
              annualRate: v.number('rate'),
              method: v.text('method'),
              compoundingMonths: int.parse(v.text('compound')),
              tenureMonths: v.integer('tenure'),
              parcelId: v.text('parcel').isEmpty ? null : v.text('parcel'),
              concession: v.flag('concession'),
              notes: v.text('notes'),
              withdrawn: v.money('withdrawn'),
            );
      },
    );
  }

  Future<void> _transaction(
    BuildContext context,
    WidgetRef ref,
    LoanView view,
  ) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xAddTransaction,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(todayProvider),
        ),
        EntryField(
          'kind',
          l.xType,
          kind: InputKind.choice,
          required: true,
          initial: 'principal',
          options: {
            for (final k in ['withdrawal', 'principal', 'interest', 'charge'])
              k: recordLabel(context, k),
          },
        ),
        EntryField(
          'amount',
          l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
        EntryField(
          'mode',
          l.payment,
          kind: InputKind.choice,
          initial: 'cash',
          options: {'cash': l.modeCash, 'upi': l.modeUpi, 'bank': l.xBank},
        ),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (v) => ref
          .read(loansRepositoryProvider)
          .addTransaction(
            loanId: view.loan.id,
            date: v.date('date'),
            kind: v.text('kind'),
            amount: v.money('amount'),
            mode: v.text('mode'),
            note: v.text('notes'),
          ),
    );
  }

  Future<void> _due(BuildContext context, WidgetRef ref, Loan loan) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xAddReminder,
      fields: [
        EntryField('title', l.xTitle, required: true, initial: loan.lender),
        EntryField(
          'date',
          l.xDueOn,
          kind: InputKind.date,
          required: true,
          initial: ref.read(todayProvider).add(const Duration(days: 30)),
        ),
        EntryField('amount', l.xAmount, kind: InputKind.money),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (v) async {
        final db = ref.read(databaseProvider);
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: v.text('title'),
                dueOn: v.date('date'),
                kind: const Value('loan'),
                refId: Value(loan.id),
                amount: Value(
                  v.money('amount') == 0 ? null : v.money('amount'),
                ),
                notes: Value(v.text('notes')),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return RecordPage(
      title: l.xLoans,
      value: ref.watch(loansProvider),
      intro: l.xLoanEstimate,
      onAdd: () => _add(context, ref),
      actions: [
        IconButton(
          icon: const Icon(Icons.card_membership_outlined),
          tooltip: l.xMembership,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MembershipsScreen()),
          ),
        ),
      ],
      itemBuilder: (LoanView v) => RecordItem(
        id: v.loan.id,
        title: v.loan.lender,
        subtitle:
            '${recordLabel(context, v.loan.kind)} · ${recordLabel(context, v.loan.status)} · ${context.fmt.money(v.balance.total)}',
        refType: 'loan',
        details: {
          l.xSanctioned: context.fmt.money(v.loan.sanctioned),
          l.xOutstanding: context.fmt.money(v.balance.principal),
          l.xAccruedInterest: context.fmt.money(v.balance.interest),
          l.xInterestPaid: context.fmt.money(v.balance.interestPaid),
          l.xAnnualRate: '${v.loan.annualRate}%',
          l.xInterestMethod: recordLabel(context, v.loan.interestMethod),
          if (v.loan.timelyConcession) l.xConcession: '✓',
          l.notes: v.loan.notes,
        },
        actions: [
          for (final t in v.transactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(recordLabel(context, t.kind)),
              subtitle: Text('${context.fmt.date(t.date)} · ${t.note}'),
              trailing: Text(context.fmt.money(t.amount)),
              onLongPress: v.loan.status != 'active'
                  ? null
                  : () async {
                      if (await confirm(context, title: l.confirmDelete) &&
                          context.mounted) {
                        await perform(
                          context,
                          () => ref
                              .read(loansRepositoryProvider)
                              .deleteTransaction(t.id),
                        );
                      }
                    },
            ),
          if (v.loan.status == 'active') ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.xAddTransaction),
              onPressed: () => _transaction(context, ref, v),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_outlined),
              label: Text(l.xAddReminder),
              onPressed: () => _due(context, ref, v.loan),
            ),
            if (v.balance.total == 0)
              TextButton(
                onPressed: () => perform(
                  context,
                  () => ref
                      .read(loansRepositoryProvider)
                      .close(v.loan.id, ref.read(todayProvider)),
                ),
                child: Text(l.xClosed),
              ),
          ],
        ],
      ),
    );
  }
}

class MembershipsScreen extends ConsumerWidget {
  const MembershipsScreen({super.key});
  Future<void> _member(
    BuildContext context,
    WidgetRef ref, [
    Membership? member,
  ]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xMembership,
      fields: [
        EntryField(
          'org',
          l.xOrganization,
          required: true,
          initial: member?.organization,
        ),
        EntryField(
          'number',
          l.xMemberNumber,
          required: true,
          initial: member?.memberNumber,
        ),
        EntryField(
          'shares',
          l.wOpeningShares,
          kind: InputKind.quantity,
          initial: qtyToInput(member?.shares),
        ),
        EntryField(
          'value',
          l.xShareValue,
          kind: InputKind.money,
          initial: paiseToInput(member?.shareValue),
        ),
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: member?.joinedOn ?? ref.read(todayProvider),
        ),
      ],
      onSave: (v) async {
        await ref
            .read(membershipsRepositoryProvider)
            .save(
              id: member?.id,
              organization: v.text('org'),
              number: v.text('number'),
              joinedOn: v.date('date'),
              shares: v.number('shares'),
              shareValue: v.money('value'),
            );
      },
    );
  }

  Future<void> _transaction(
    BuildContext context,
    WidgetRef ref,
    Membership member, {
    String kind = 'dividend',
    MembershipTransaction? existing,
  }) async {
    final l = context.l;
    final purchase = kind == 'share_purchase';
    await openEntryForm(
      context,
      title: purchase ? l.xSharePurchase : l.xDividend,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: existing?.date ?? ref.read(todayProvider),
        ),
        EntryField(
          'amount',
          l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: paiseToInput(existing?.amount),
        ),
        if (purchase)
          EntryField(
            'shares',
            l.xShares,
            kind: InputKind.quantity,
            required: true,
            positive: true,
            initial: qtyToInput(existing?.shares),
          ),
      ],
      onSave: (v) async {
        await ref
            .read(membershipsRepositoryProvider)
            .transaction(
              id: existing?.id,
              membershipId: member.id,
              date: v.date('date'),
              kind: kind,
              amount: v.money('amount'),
              shares: purchase ? v.number('shares') : 0,
            );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => RecordPage<MembershipView>(
    title: context.l.xMembership,
    value: ref.watch(membershipsProvider),
    onAdd: () => _member(context, ref),
    itemBuilder: (v) => RecordItem(
      id: v.member.id,
      title: v.member.organization,
      subtitle: v.member.memberNumber,
      refType: 'membership',
      details: {
        context.l.xShares: formatQty(v.shares),
        context.l.wOpeningShares: formatQty(v.member.shares),
        context.l.xShareValue: formatRupees(v.member.shareValue),
      },
      onEdit: () => _member(context, ref, v.member),
      onDelete: () =>
          ref.read(membershipsRepositoryProvider).delete(v.member.id),
      actions: [
        for (final t in v.transactions)
          ListTile(
            title: Text(recordLabel(context, t.kind)),
            subtitle: Text(
              '${context.fmt.date(t.date)}${t.kind == 'share_purchase' ? ' · ${formatQty(t.shares)} ${context.l.xShares}' : ''}',
            ),
            trailing: Text(context.fmt.money(t.amount)),
            onTap: () =>
                _transaction(context, ref, v.member, kind: t.kind, existing: t),
            onLongPress: () async {
              if (await confirm(context, title: context.l.deleteEntry) &&
                  context.mounted) {
                await perform(
                  context,
                  () => ref
                      .read(membershipsRepositoryProvider)
                      .deleteTransaction(t.id),
                );
              }
            },
          ),
        Text(context.l.wTransactionHint),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () =>
                  _transaction(context, ref, v.member, kind: 'share_purchase'),
              child: Text(context.l.xSharePurchase),
            ),
            OutlinedButton(
              onPressed: () => _transaction(context, ref, v.member),
              child: Text(context.l.xDividend),
            ),
          ],
        ),
      ],
    ),
  );
}
