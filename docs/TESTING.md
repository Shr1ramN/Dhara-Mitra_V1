# Testing Dhara Mitra

From `app/`, run `flutter analyze`, `flutter test` and `flutter build apk --debug`. CI also lints workflows, scans the Dart lockfile and builds a release-mode APK.

## Android acceptance checklist

Use sample data or an isolated test farm. Record the app version, Android version, device and language. Save a backup outside the app before testing an upgrade or restore.

- [ ] Farm Tools opens Add Farm Activity, Sold to Buyer and Labour Management.
- [ ] Money shows worker dues and crop sale income. View sales opens Calendar at Matching records, including with zero sales.
- [ ] Calendar opens at the top from its tab. Applying filters or submitting a search brings Matching records into view.
- [ ] Work, harvest quantities and single- or multi-crop sales survive a restart offline.
- [ ] Attendance, loans and settlements reconcile with worker balances and reports.
- [ ] Farms keep separate records. Restores preserve the expected records and attachments. Invalid archives leave existing records intact.
- [ ] Kannada and English fit narrow screens and large text. Check the keyboard, themes and Android Back.
- [ ] App lock and file sharing work, including when permissions are denied or the action is cancelled.
- [ ] Excel and SQLite exports contain the expected records. An in-place APK update preserves local data.

Record actual outcomes and report failures through the [bug form](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues/new?template=bug_report.yml). Use sample records and remove personal information.
