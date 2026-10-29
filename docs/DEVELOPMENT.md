# Development guide

## Prerequisites

| Tool | Project configuration |
| --- | --- |
| Flutter | 3.47.8, matching `.github/workflows/android.yml` |
| Dart | 3.13.7, bundled with Flutter |
| Java | JDK 17 |
| Android | Android Studio or command-line SDK, platform/build tools required by Flutter and plugins |
| Git | Clone the repository and push a working branch |
| Test device | Android phone with USB debugging or a working emulator |

On Windows, keep SDKs in paths without spaces where practical. Set `JAVA_HOME` to JDK 17, configure the Android SDK, and add Flutter and Android `platform-tools` to `PATH`. `flutter config --jdk-dir <jdk-path>` and `flutter config --android-sdk <sdk-path>` can select existing installations. Use Windows Developer Mode if Flutter reports that plugin symlinks require it.

Run `flutter doctor -v`, resolve Android toolchain errors and accept SDK licences using `flutter doctor --android-licenses`. Android Studio installs SDK components; a Visual Studio desktop toolchain is not required for Android-only work.

## First run

```sh
git clone --branch develop https://github.com/Shr1ramN/Dhara-Mitra.git
cd Dhara-Mitra/app
flutter pub get
flutter devices
flutter run -d <device-id>
```

These commands select the latest merged development app. Create feature branches from `develop` and open a PR back to it.

Generated Dart files and bundled fonts are in Git. You do not need Supabase, a data.gov.in key or runtime font downloads for the existing offline app. Weather refresh requires connectivity and a configured farm location.

## Physical phone over USB

1. On the phone, enable Developer options and USB debugging.
2. Connect a cable that supports data, unlock the phone and accept its debugging prompt. Select File transfer if the device requires it.
3. Run `adb devices -l`, then `flutter devices`.
4. Run `flutter run -d <device-id>` using the physical phone's ID, especially if an emulator is also listed.

| Symptom | Next check |
| --- | --- |
| `unauthorized` | Unlock the phone and accept the debugging prompt |
| Device missing | Check the cable, USB mode and manufacturer's Windows ADB driver |
| Emulator is offline | Select the physical phone explicitly; a phone does not need an emulator |
| Build fails | Read the first relevant build error and run `flutter doctor -v`; preserve the log without sharing secrets |
| APK update rejected | Compare package ID, signing certificate and version code; back up before any uninstall |

## Everyday checks

From `app/`:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Use `flutter test test/data/expanded_workflows_test.dart` for the expanded repository regression suite. Choose focused tests while changing code, then run the complete suite before submitting.

## Database and localization changes

```sh
dart run build_runner build
flutter gen-l10n
```

The database is defined in `lib/core/db/tables.dart`, `extended_tables.dart` and `database.dart`. Schema version 4 adds daily-work allocations shared by diary, areca and other-produce labour; version 3 added worker contacts/roles, bag quantities and collection records. Version 4 reconciles valid historical daily-wage duplicates into attendance, preserves original work transaction records as soft-deleted entries, and retains actual payments and manual attendance. Existing v1/v2 records migrate in place. Each farm profile has its own SQLite database; the legacy default profile keeps the original database filename. The profile catalogue is outside the databases so a single-farm restore cannot remove other profiles. Attachments and notification IDs are profile-scoped. Every later installed schema change needs a forward migration and tests preserving existing records. Never use a database wipe as an upgrade strategy.

Edit both `lib/l10n/app_en.arb` and `app_kn.arb` when adding text. Commit the regenerated localization files. Store monetary amounts as integer paise, preserve quantity units, and respect the configured season start month.

## Repository layout

```text
.github/                CI, issue forms and pull-request template
app/                    Flutter application and Android platform code
  lib/core/             Database, services, notifications and shared utilities
  lib/features/         Feature repositories, calculations and screens
  lib/l10n/             English and Kannada translations
  test/                 Unit, repository, migration and widget tests
docs/                   Plan, status, development and testing guides
prototype/              Browser design reference with sample data
```

## Data and credentials

Keep real farm records, database exports, photos, API keys and private signing keys out of Git and issue attachments. Use synthetic data in tests. The optional app lock uses device authentication; it does not encrypt the SQLite database or exported archives. See [security](../SECURITY.md).

Automatic market-price collection and Supabase backup are future integrations tracked separately. Do not add fake live rates or put private server credentials in the app to bypass account setup.
