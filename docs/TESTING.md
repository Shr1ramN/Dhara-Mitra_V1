# Testing and acceptance

## Automated checks

Run from `app/`:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

CI runs analysis, tests and a release-mode Android build in that order. Informational analyzer findings also fail the check. A green build verifies those automated steps; it does not establish that every plugin works on a physical phone.

The recorded baseline suite has 76 passing tests covering calculations, repositories, migrations, backup validation and widget rendering. See the latest CI run for results after subsequent changes. Add focused regression tests when fixing financial calculations or data relationships.

## Before device acceptance

- Create a full local ZIP backup including attachments and keep a copy outside the phone.
- Use synthetic records or an isolated test installation. Do not fill the owner's real farm database with test entries.
- Record the commit, APK/build number, Android version, model and language.
- Keep an existing dataset for in-place migration/upgrade verification.

Final manual acceptance is deferred in [#14](https://github.com/Shr1ramN/Dhara-Mitra/issues/14). Phone-setting setup is separately tracked in [#16](https://github.com/Shr1ramN/Dhara-Mitra/issues/16).

## Phone acceptance checklist

- [ ] Farm/plot setup, crop details, units and configurable season boundaries persist after restart.
- [ ] Attendance → diary and diary → attendance reuse daily wages; extra piecework is additional. Verify harvest allocation once [#3](https://github.com/Shr1ramN/Dhara-Mitra/issues/3) is resolved.
- [ ] Stock purchase → diary usage updates quantities, valuation and labour atomically; rejected edits leave records unchanged.
- [ ] Areca completes every stage; pepper, coconut/copra and banana retain correct quantities/units through partial sales.
- [ ] Sales deductions, receipts, worker payments, loan withdrawals/repayments, interest, insurance and subsidies reconcile with reports.
- [ ] Edit/delete/correction paths preserve linked records, balances, stock and reminders.
- [ ] Kannada/English forms fit narrow screens, keyboard and large text; financial values use Indian formatting.
- [ ] Camera/gallery/files, recording/playback, speech, GPS and authentication work; denial/cancellation has a usable recovery path.
- [ ] PDF and Excel contain correct filtered totals and readable Kannada; share/open the generated files.
- [ ] Rain, stock, dues and task notifications update/cancel correctly; check background/reboot behavior without assuming exact delivery times.
- [ ] Create/restore a full ZIP on isolated data, including documents. Malformed archives must not overwrite current records.
- [ ] Install over the previous app version and confirm record counts, representative balances and attachments are preserved.

## Offline day

1. Save a forecast and manual prices while connected.
2. Disconnect the test device from the network.
3. Add attendance, purchases, diary work, a harvest, sale, payment and expense; generate a report and local backup.
4. Restart the app and confirm entries and cached timestamps remain correct.
5. Reconnect and verify implemented refresh/alert flows. Live price imports and cloud backup cannot be accepted until their separate integrations exist.

Record actual outcomes rather than marking a feature verified because its screen opens. File failures with steps, expected/actual results and sanitized screenshots using the [bug form](https://github.com/Shr1ramN/Dhara-Mitra/issues/new?template=bug_report.yml).
