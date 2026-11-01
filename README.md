# Dhara Mitra · ಧರಾ ಮಿತ್ರ

**Your farm records, organised by date. In Kannada and English.**

[![Android checks](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml/badge.svg?branch=develop)](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Dhara Mitra is an Android farm diary for keeping everyday work, labour, harvests and payments together. Records stay on your phone, so you can record work and look back through your farm's history offline.

[Download a test APK](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases) · [Source code](https://github.com/Shr1ramN/Dhara-Mitra_V1) · [Report an issue](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues)

## V3: everyday work made simpler

| Screen | What you can do |
| --- | --- |
| **Home** | See attendance, worker dues, recent farm activity and harvests. Open Labour Management, Farm Activity, Harvest or Calendar. |
| **Calendar** | Tap a date to immediately choose Labour Management, Farm Activity, Harvest or Sold to Buyer. Search saved history by date, words and category. |
| **Labour Management** | Add workers, mark full/half/absent attendance with automatic saving, settle wages, manage worker loans and review weekly/monthly/yearly reports. |
| **More** | Edit farm details and your own crops, switch farms, choose English/Kannada and Light/Dark/System default, export data, back up/restore and manage the app lock. |

Daily-wage workers have a saved rate; other workers have a wage entered for each attended day. Attendance records one description of the day's work. Worker profiles retain previous and new loans, repayments, settlements and balances in integer paise.

Farm Activity combines irrigation, fertiliser, spray and custom labelled notes. Use + chips to add named types/crops, and long-press work suggestions to remove them without deleting records. Harvest accepts your crop and a quantity in bags or kilograms. Sales support multiple crops for one buyer, item quantities/units, total income and optional notes. Edited forms warn before discarding unsaved changes.

Farm setup needs no plots or tree counts: **What do you grow?** is freely editable.

**Export to Excel** creates an editable `.xlsx` snapshot with readable labour/activity/harvest sheets, stable IDs, exact paise alongside rupee amounts, and raw historical tables. Editing the workbook does not change the app. Backup/restore and database export remain available separately.

V3 hides market prices, weather/rain reminders, sales/buyers, farm loans, land parcels, insurance and schemes. Existing records are retained in storage, backups and raw Excel sheets. Worker loans remain in Labour Management.

The interface and bundled fonts support Kannada and English. Records work offline and stay on your phone. Install updates over the existing app to retain its records.

## Install on Android

1. Open [Releases](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases) and select the latest **Dhara Mitra V3** release.
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

Pull requests to `develop` or `master` require owner review, passing analysis/tests and a successful Android APK build. Download the PR APK from its Actions run to test the proposed change.

After an approved merge, `develop` publishes **DharaMitra.apk** as a Develop preview prerelease. `master` publishes a regular GitHub release marked Latest. Both include checksums and the source commit. The current APK retains the existing public development signing key; private production signing is still pending.

## Feedback and contributions

[Report a bug](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues/new/choose) or suggest a farm workflow using the issue templates. See [Contributing](CONTRIBUTING.md) and [Security](SECURITY.md). Use sample records and remove personal farm data from screenshots.

## License

Code is available under the [MIT License](LICENSE). Bundled fonts retain their [Open Font License notices](app/assets/fonts/).
