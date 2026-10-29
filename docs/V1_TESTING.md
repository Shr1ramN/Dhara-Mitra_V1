# V1 user testing

Branch: `V1-Dev`, based on develop commit `4c9bdd1`.

Run from `app/` with Flutter 3.47.8:

```
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Install `app/build/app/outputs/flutter-apk/app-release.apk` on Android. Every V1-Dev push runs checks, builds the APK, and publishes a GitHub prerelease named `V1-Dev preview <run>.<attempt>`. Download `dhara-mitra-v1.apk` directly from that release. GitHub Actions also retains the `dhara-mitra-v1-testing-apk` artifact. This is a development-signed testing build.

Test in English and Kannada with airplane mode enabled:

1. Open without login; create a farm, add plots, switch between farms and reopen the app.
2. Add workers and rates. In Calendar choose a past date, add attendance, record a payment and check outstanding dues. Diary daily labour should reuse that attendance wage.
3. Record manure, fertilizer and spraying with remarks. Add a standalone date note. Search `manure`, `ಗೊಬ್ಬರ`, and `when did I last put manure`; check newest match, older records, highlighted dates and an unknown keyword.
4. Use category/date-range filters and select individual dates. Open and edit activities, attendance, expenses, harvests, sales and payments.
5. Record arecanut harvest in bags or kg, continue its existing processing and grading steps, then sell. Record coconut harvest under Produce and sell nuts directly, or continue processing for copra.
6. Record buyers, partial receipts and later dated receipts. Verify remaining quantities, pending balances, receipt calendar dates, and rejection of overpayment/overselling.
7. Record materials, transport and other expenses. Worker payments belong under Workers, not another manual expense. Home monthly costs count earned wages once, not both wages and payments.
8. Under More → Backup, export all farms. Transfer the ZIP to another phone, import it and select the imported farms. Check records, date notes, receipts and attachments. Single-farm restore replaces that farm after confirmation; export before testing restore.

Existing records and hidden feature tables are retained. Schema 5 adds dated sale receipts; earlier received totals migrate as opening received balances on the original sale date because the old database did not retain payment dates. Search is deterministic keyword matching, not general natural-language understanding. Physical-device testing and user acceptance are required before merging or release.
