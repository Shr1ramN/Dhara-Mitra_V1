# Dhara Mitra Android app

The Flutter app behind Dhara Mitra's **Home**, **Calendar** and **More** screens. It uses Riverpod, GoRouter and a local Drift/SQLite database. Android is the supported target. See the [project overview](../README.md) for the available product features.

## Run and check

Install **Flutter 3.47.8 / Dart 3.13.7**, **JDK 17** and the Android SDK. Run from this folder:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Core record keeping requires no cloud account. CI runs analysis and tests before building an APK. Phone testing is still needed for device features such as file sharing, app locking and installation updates.

## Generated sources and migrations

Generated database and localisation Dart files are committed. After changing their sources, run:

```sh
dart run build_runner build
flutter gen-l10n
```

Database definitions are in `lib/core/db/tables.dart` and `extended_tables.dart`. Schema changes for an installed app require a new schema version and an upgrade migration in `database.dart`. Preserve existing user records when changing migrations.

## APKs and signing

- Debug output: `build/app/outputs/flutter-apk/app-debug.apk`.
- Release build: `flutter build apk --release` produces `build/app/outputs/flutter-apk/app-release.apk`.
- Both build modes use the existing public test key, `android/app/dev-signing.p12`, and app ID `in.dharamitra.app` for development update compatibility.
- CI names the installable asset **DharaMitra.apk** and sets the version code to `20000 + github.run_number`.
- Develop pushes publish a test prerelease. An explicit workflow run on `master` builds an artifact without publishing a release.

Keep the app ID and signing certificate unchanged when testing updates on phones with existing records. Export a backup before updating.

## Source layout

- `lib/core/`: database, providers, services, formatting and shared UI.
- `lib/features/`: screens and feature logic, including the calendar record index and editors.
- `lib/l10n/`: English/Kannada ARB sources and generated localisations.
- `assets/fonts/`: bundled fonts and license notices.
- `test/`: calculation, repository, migration and widget checks.
- `android/`: platform permissions, activity, Gradle configuration and test signing.

Some feature source remains in the repository for data compatibility without appearing in the current navigation. The presence of source files alone does not mean a feature is available in the app.
