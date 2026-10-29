# Dhara Mitra Android app

Flutter application with Riverpod state, GoRouter navigation and a local Drift/SQLite database. Android is the supported development target.

## Run

Install Flutter **3.47.8** (Dart **3.13.7**), JDK **17** and the Android SDK, then run from this folder:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

No cloud account is required for offline development. See [machine and USB setup](../docs/DEVELOPMENT.md) and the [project overview](../README.md).

## Validate

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Analysis findings fail CI, including informational lints. Fix the source rather than disabling the gate. Device plugins also require the [phone acceptance checks](../docs/TESTING.md).

## Generated files

Generated database and localization Dart files are committed. After changing their sources, run:

```sh
dart run build_runner build
flutter gen-l10n
```

Database definitions are in `lib/core/db/tables.dart` and `extended_tables.dart`. Schema changes to an installed version require a new version and an upgrade migration in `database.dart`; never rewrite an already deployed migration to reset user data.

## Build outputs and signing

- Debug: `build/app/outputs/flutter-apk/app-debug.apk`.
- Release mode: `flutter build apk --release`, producing `build/app/outputs/flutter-apk/app-release.apk`.
- Both currently use the intentionally public test key `android/app/dev-signing.p12`. This provides development update compatibility, not production authenticity.
- Production signing and distribution remain deferred. Read [release preparation](../docs/RELEASING.md) before changing signing or version codes.

## Layout

- `lib/core/`: database, app services, notifications, providers, formatting and shared UI.
- `lib/features/`: farm, labour, lots, diary, stock, produce, sales, finance, loans, reports, documents, weather, prices, reminders, security and backup.
- `lib/l10n/`: English/Kannada ARB sources and generated localizations.
- `assets/fonts/`: bundled fonts and license notices.
- `test/`: calculation, repository, migration and widget tests.
- `android/`: platform permissions, activity, Gradle configuration and development signing.
