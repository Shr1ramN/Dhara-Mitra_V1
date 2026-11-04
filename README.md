# Dhara Mitra · ಧರಾ ಮಿತ್ರ

**An offline Android farm diary in Kannada and English.**

[![Android checks](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml/badge.svg?branch=master)](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Dhara Mitra keeps farm activities, harvests, crop sales and labour records together by date. It saves records on your phone and works without an account or internet connection.

## Install on Android

1. Open the [latest GitHub release](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases/latest).
2. Download **DharaMitra.apk** from Assets and open it on your phone. Android may ask you to allow installation from your browser or file manager.
3. Before updating, use **More → Backup and restore** to save a copy outside the app. Install over the existing app to keep your records.

GitHub APKs use a **public development signing key** for compatibility with previous test builds. Releases include the source commit and a SHA-256 checksum. See the [security policy](SECURITY.md) for details.

## What you can do

| Area | Features |
| --- | --- |
| Home | See attendance, worker dues, recent work and harvest counts. Farm Tools opens Add Farm Activity, Sold to Buyer or Labour Management. Money links to sales and labour reports. |
| Calendar | Tap a date to add work, attendance, harvest or sales. Apply filters or submit a search to jump to Matching records. View sales opens that section with crop sales selected. |
| Farm records | Record irrigation, fertiliser, spray and custom work. Enter harvests in bags or kilograms. Save sales with multiple crops, item quantities and total income. |
| Labour Management | Record full days, half days and absences, settle wages, track worker loans and review weekly, monthly or yearly reports. |
| More | Manage separate farms and crops, choose language and theme, use the app lock, back up and restore, and export Excel or SQLite snapshots. |

Excel snapshots include readable sheets and raw historical tables. Earlier modules such as market prices, weather, stock and farm finance remain in the source and storage schema for compatibility. See the [implementation overview](docs/IMPLEMENTATION_STATUS.md).

## Build locally

Use **Flutter 3.47.8 / Dart 3.13.7**, **JDK 17** and the Android SDK.

```sh
git clone --branch develop https://github.com/Shr1ramN/Dhara-Mitra_V1.git
cd Dhara-Mitra_V1/app
flutter doctor -v
flutter pub get
flutter devices
flutter run -d <device-id>
```

From `app/`, run `flutter analyze`, `flutter test` and `flutter build apk --debug`. The debug APK is at `app/build/app/outputs/flutter-apk/app-debug.apk` from the repository root. See the [development guide](docs/DEVELOPMENT.md) for setup.

## Contribute

Read [Contributing](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). Use the [issue forms](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues/new/choose) for bugs and ideas, and [private vulnerability reporting](https://github.com/Shr1ramN/Dhara-Mitra_V1/security/advisories/new) for security issues.

Open contributor PRs against `develop`. The default branch, `master`, publishes regular releases and accepts promotion PRs from this repository's `develop` branch. GitHub Actions checks workflow syntax, resolved Dart dependencies, Flutter analysis, tests and the Android APK build. See the [testing checklist](docs/TESTING.md) and [release guide](docs/RELEASING.md).

## License

The source is available under the [MIT License](LICENSE). Bundled fonts retain their [Open Font License notices](app/assets/fonts/).
