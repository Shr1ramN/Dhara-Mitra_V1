# Dhara Mitra · ಧರಾ ಮಿತ್ರ

**Your farm records, organised by date. In Kannada and English.**

[![Android checks](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml/badge.svg?branch=develop)](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Dhara Mitra is an Android farm diary for keeping everyday work, labour, harvests and payments together. Records stay on your phone, so you can record work and look back through your farm's history offline.

[Download a test APK](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases) · [Source code](https://github.com/Shr1ramN/Dhara-Mitra_V1) · [Report an issue](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues)

## Three places for your daily work

| Screen | What you can do |
| --- | --- |
| **Home** | See recent records, drying and stored harvests, worker dues, buyer balances and this month's costs. Open everyday farm tools and switch farms. |
| **Calendar** | Select a day to review or add work, attendance, payments, expenses, harvests, sales and date notes. Search existing records by words, category or date range. |
| **More** | Manage farms and plots, open farm records and reports, switch between English and ಕನ್ನಡ, export data, and manage backup and the optional app lock. |

## Keep the farm's story together

- **Work and labour:** record farm activities, attendance, wages and worker payments.
- **Harvests:** follow arecanut from collection through drying, peeling, grading and storage; record coconut harvests too.
- **Sales and expenses:** record buyers, sales, receipts, outstanding amounts and farm spending.
- **Calendar history:** find recorded work such as manure application or spraying, then open the original entry. Keyword search works locally on your saved records.
- **Reports:** review farm totals and export reports as PDF or Excel.
- **Separate farms:** switch between farms with independent records and balances.

The interface and bundled fonts support Kannada and English. Core record keeping works offline. Data is stored locally; save backups outside the app regularly and before installing an update. A database export is also available under **More**.

## Install on Android

1. Open [Releases](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases) and select a **Develop preview**.
2. Download **DharaMitra.apk** from its assets directly to your phone.
3. Open the APK and allow installation from your browser or file manager if Android requests it.

These are test builds signed with the project's existing public development key. Each preview includes its source commit and `SHA256SUMS`. Updating an existing installation requires the same app ID and signing certificate, with a higher version code. Export a backup first; uninstalling or clearing app storage removes local records.

## Develop locally

Use **Flutter 3.47.8 / Dart 3.13.7**, **JDK 17**, and the Android SDK. From a checkout of this repository:

```sh
git clone --branch develop https://github.com/Shr1ramN/Dhara-Mitra_V1.git
cd Dhara-Mitra_V1/app
flutter pub get
flutter devices
flutter run -d <device-id>
```

Run checks from `app/`:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is at `app/build/app/outputs/flutter-apk/app-debug.apk` from the repository root. See the [app development notes](app/README.md) for generated files and signing details.

## Build delivery

Pull requests to `develop` or `master` run analysis and tests. Pushes to `develop` run the same checks, build **DharaMitra.apk**, and publish a **Develop preview** prerelease. Feature branches and pushes to `master` do not automatically build or publish APKs.

A maintainer can explicitly run **Android quality and delivery** on `master` to check and build a downloadable test APK. That manual run does not publish a release. CI version codes use `20000 + github.run_number`, above the earlier `10030` build, while retaining the existing app ID and signing key.

## License

Code is available under the [MIT License](LICENSE). Bundled fonts retain their [Open Font License notices](app/assets/fonts/).
