# Android releases

`master` is the default branch and the source for regular releases. Contributor PRs target `develop`. Open release PRs from `Shr1ramN/Dhara-Mitra_V1:develop` to `master`.

Both branches use the existing review and Android check rules. The release branch also requires **Verify promotion from develop**. Its workflow runs from `master` and verifies the PR's source branch and repository. Use a merge commit for promotions to preserve shared history. After releasing, fast-forward `develop` to the promotion merge when possible.

## Build and verify

1. Check the app version in `app/pubspec.yaml` and the relevant [phone acceptance checks](TESTING.md).
2. Confirm the PR checks pass and resolve review conversations before merging.
3. Watch the [Android workflow](https://github.com/Shr1ramN/Dhara-Mitra_V1/actions/workflows/android.yml). Pushes with changes under `app/` publish a prerelease from `develop` or a regular release from `master`. Docs and workflow changes still run checks.
4. Check that the release has **DharaMitra.apk**, **SHA256SUMS** and the source commit. Compare the downloaded APK's SHA-256 to the checksum and describe the user-visible changes in the release notes.

The app ID is `in.dharamitra.app`. CI sets Android version codes to `20000 + github.run_number`. The public development signing certificate keeps updates compatible with existing test installs. See [Security](../SECURITY.md).

Before testing an update on a phone, export a backup. Install over the previous build and verify representative records, balances and attachments.
