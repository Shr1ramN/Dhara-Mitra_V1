# Contributing to Dhara Mitra

Start with the [README](README.md), [development guide](docs/DEVELOPMENT.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## Report a bug or suggest an improvement

Search [existing issues](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues) first. Use the [issue forms](https://github.com/Shr1ramN/Dhara-Mitra_V1/issues/new/choose) and include the app version, Android version, language, steps to reproduce and expected behavior. For an idea, describe the farm workflow and how it should work offline.

Use sample records. Remove names, phone numbers, balances, coordinates, photos and credentials from screenshots and logs. Report vulnerabilities privately using the [security policy](SECURITY.md).

## Open a pull request

1. Fork the repo, start from `develop` and use a focused branch such as `dev/fix-calendar-search`.
2. Update English and Kannada together when UI text changes. Commit regenerated sources when required.
3. From `app/`, run `flutter pub get`, `flutter analyze`, `flutter test` and `flutter build apk --debug`. Add focused regression coverage for changes to money, migrations or linked records.
4. Open the PR against `Shr1ramN/Dhara-Mitra_V1:develop`. Link the issue and describe the change and checks you ran. For visible changes, include screenshots with sample data and list any remaining phone checks.
5. Respond to review and resolve conversations before merging. CI lints workflows, scans the Dart lockfile, analyzes and tests Flutter, and builds an Android APK.

Maintainers promote `develop` to `master` through a PR from this repository's own `develop`. See the [release guide](docs/RELEASING.md).

## Preserve farm records

Store money as integer paise and preserve quantity units. Update linked wages, sales and balances in a transaction. Use forward migrations and test them against existing data. Keep core workflows usable offline. Keep personal records and private keys out of Git, and retain project and bundled asset license notices.
