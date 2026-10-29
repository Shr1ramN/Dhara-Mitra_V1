# Implementation status

Phase-one sign-in is implemented with Supabase Auth: Google OAuth, email/password,
email confirmation/recovery, and persistent local mode with a data-loss warning.
Account farm catalogues are separate from the preserved legacy local catalogue.
Cloud backup remains deferred; every mode requires manual backups. Live sign-in
acceptance needs Supabase configuration and Android callback testing. See
[authentication setup](AUTHENTICATION.md).

The expanded baseline from PR #21 is merged into `develop`; the farmer workflow update is proposed from `codex/farmer-workflows-and-delivery`. It is a development preview, not a completed release. The [pending-work tracker](https://github.com/Shr1ramN/Dhara-Mitra/issues/20) links the remaining implementation and verification issues.

User decisions:
- The owner will install the development release APK later; this update does not change the phone.
- Finish remaining implementation and API setup before final phone testing.
- Supabase farm-data backup, phone-setting changes, final phone acceptance and production release preparation are deferred.
- Daily diary labour MUST reuse attendance wages; separate piecework is additional.
- Testing is authorized, but preserve existing real farm records.

Database schema is version 4. Forward migrations preserve installed v1/v2 records, including their kilogram units and balances. Preserve backups outside the phone before updating; do not clear or uninstall the app to resolve an upgrade problem.

Implemented in source, final verification still required:
- Diary CRUD, search/crop/plot/type/date filters; stock consumption and wage links.
- Stock purchase history with moving average valuation and low-stock thresholds.
- Expenses; sales/buyers and receipts; safeguards against overselling/overpayment.
- Separate pepper, coconut/copra and banana harvest lots with units and labour.
- Loans and tested interest calculations; land, membership, policies/claims/schemes.
- Reports, crop/plot allocation, PDF (Flutter-rendered Kannada) and Excel exports.
- Photo/file/voice attachments, speech-to-text notes, document vault.
- Weather cache, forecast and rain log; manual price history/charts and alerts.
- Reminders/calendar CRUD, phone notifications, background weather/alert refresh.
- Device-auth app lock and secure window flag.
- Full ZIP backup/restore with snapshot, checksums, attachment validation and rollback.
- Crop profiles, varieties, planting date, bearing/ratoon/trailing; per-work wage rates.

## Validation

The farmer workflow update passes 89 tests and static analysis without issues. Tests cover diary/attendance reuse in both entry orders, piecework, produce units/partial sales, report allocation, weather cache behavior, migration and backup validation. The new routes and home shortcuts are wired. These are not pending implementations.

PR #21's original CI run failed on 16 analyzer findings, before tests/build. The branch correction fixes the findings without weakening analysis; local analysis reports no issues. Consult the current [Android workflow](https://github.com/Shr1ramN/Dhara-Mitra/actions/workflows/android.yml) for the latest commit's full analysis/test/build result.

Physical-device acceptance of the expanded workflows remains incomplete. No claim is made that all F1–F12 requirements or device plugins are verified.

## Remaining implementation

- [Live market feeds and scheduled history](https://github.com/Shr1ramN/Dhara-Mitra/issues/1), including the separate price-only backend in #2.
- Daily-wage reuse across diary/areca/produce is implemented in schema 4; review and merge tracking remains in #3.
- Membership holdings and transaction corrections are implemented (#4); broader missing [financial](https://github.com/Shr1ramN/Dhara-Mitra/issues/5) / [stock and sales](https://github.com/Shr1ramN/Dhara-Mitra/issues/6) correction paths.
- [Purchase bill links](https://github.com/Shr1ramN/Dhara-Mitra/issues/7), [report KPIs/comparisons](https://github.com/Shr1ramN/Dhara-Mitra/issues/8), and [current stored-lot valuation](https://github.com/Shr1ramN/Dhara-Mitra/issues/9).
- [Connectivity/freshness](https://github.com/Shr1ramN/Dhara-Mitra/issues/10), [reminder lifecycle verification](https://github.com/Shr1ramN/Dhara-Mitra/issues/11), and [sourced insurance deadlines](https://github.com/Shr1ramN/Dhara-Mitra/issues/12).
- [Code/build verification](https://github.com/Shr1ramN/Dhara-Mitra/issues/13), [latest development-build installation](https://github.com/Shr1ramN/Dhara-Mitra/issues/15), and the remaining [F1–F12 documentation/design audit](https://github.com/Shr1ramN/Dhara-Mitra/issues/19).

## Deferred

- [Final end-to-end phone acceptance](https://github.com/Shr1ramN/Dhara-Mitra/issues/14).
- [Optional phone setup](https://github.com/Shr1ramN/Dhara-Mitra/issues/16).
- [Supabase backup/new-phone restore](https://github.com/Shr1ramN/Dhara-Mitra/issues/17). Local ZIP backup is implemented.
- [Production signing/release preparation](https://github.com/Shr1ramN/Dhara-Mitra/issues/18). Current APKs use the public development signing key.

Use the [development](DEVELOPMENT.md), [testing](TESTING.md) and [release](RELEASING.md) guides for reproducible commands and acceptance checklists. Prototype screenshots remain design references with sample data.

Do not use unapproved speculative disease diagnosis, family sharing, etc. Ideas
I1/I2/I5-I7 are explicitly unaccepted in PLAN and are outside the current core scope.


## Farmer workflow update (2026-10-27)

- Farm location uses an optional map pin/GPS; no coordinate entry fields.
- Independent farm profiles isolate all repositories, attachments, weather, notifications and reports. Per-farm restore and all-farm backup/import are supported; import creates new profiles without overwriting existing farms.
- Attendance has per-worker work descriptions and an explicit apply-to-all action. Workers have reusable custom roles, Indian mobile/landline validation and dialler actions. Payroll contacts are farm-specific, not shared accounts.
- Daily collections preserve date, plots, quantity and unit; selected pickups form one drying lot or separate lots. Assignment is transactional and prevents duplicate grouping. Bags remain distinct from kg and post-peeling storage packaging. Missing measurements stay unknown and can be filled later.
- Fertilizer has a Home shortcut to the integrated diary/stock workflow.
- Schema 3 preserves installed v1/v2 data. UPI app integration is deferred in #26.
- CI separates required PR tests from develop push APK publication. Direct APK assets are published on GitHub Releases; no binary is committed to develop.

+
+## Financial consistency update (2026-10-27)
+
+Issues #3 and #4 are addressed in source with repository and bilingual form regressions. Daily work allocates one attendance wage across tasks, conserves every paise, follows attendance edits and distinguishes automatic attendance from manual attendance during deletion. Multi-day work uses consecutive dates; new daily quantities must be half-day increments up to 366 days. Piecework remains independent. Reports retain unallocated attendance costs instead of losing them when a task is removed.
+
+Schema 4 reconciles valid legacy day labour into attendance. Overlapping historical day claims share the attendance wage proportionally to their recorded days; these allocations should be reviewed if the real work split differed. Duplicate independent source work transactions are soft-deleted with their original amounts retained; source rows, payments and manual attendance remain. Corrected dues may fall, and an already-paid excess may appear as an advance. Export an all-farm backup before installing an update. Nonstandard legacy quantities/rates are retained for manual correction rather than guessed.
+
+Membership holdings derive from opening shares plus active share purchases. Purchases require positive shares/amounts; dividends do not change holdings and remain report income. Member/transaction edits and soft deletion update holdings and reports; linked documents remain accessible in the vault.
+
+Already verified in merged develop: #13 (analysis/build verification) and #22 (individual attendance work) are closed. #23, #24 and #25 remain open for their outstanding acceptance criteria; the existence of a shortcut or a partial workflow does not close the broader issue. UPI, Supabase and final phone acceptance retain their deferred status.
+
