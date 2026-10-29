# Android build and release preparation

Production release preparation is deferred in [#18](https://github.com/Shr1ramN/Dhara-Mitra/issues/18). The current workflow creates development distribution artifacts.

## Current signing

`app/android/app/build.gradle.kts` assigns both debug and release build types to the `dev` signing configuration. `app/android/app/dev-signing.p12` is intentionally committed and publicly known. It is suitable only for testing, not proof that an APK came from a trusted publisher.

Changing the signing certificate prevents a normal in-place update over an installation signed with the old certificate. Plan a backed-up data transfer when moving to production signing. Do not ask an owner to uninstall without explaining the loss of local data.

## Development builds

Run from `app/`:

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

PRs to `develop` and `master` run analysis/tests, without building an APK. After a push/merge to `develop`, successful checks allow the APK job to publish a GitHub pre-release tagged `develop-build-N-attempt`. Its Assets include the directly downloadable `dhara-mitra-v1.apk` and `SHA256SUMS`. Publication uses the job-scoped repository token; it does not push to a protected branch or require an admin credential. The APK is not committed to Git history.

Repository ruleset **Protected develop and master** requires `Analyze and test` from GitHub Actions, an up-to-date PR and one approving review. It blocks deletion/force-push; repository admins alone have bypass. A PR that changes only documentation still runs checks so it is not left permanently pending. Production release signing remains deferred.

To install a selected build on one connected device:

```sh
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
```

Back up first. Verify package ID `in.dharamitra.app`, certificate compatibility and version code before updating. Confirm launch and data retention afterwards. Installing a development update is tracked in [#15](https://github.com/Shr1ramN/Dhara-Mitra/issues/15).

## Before an accepted production release

- Complete the blocking implementation and phone acceptance issues.
- Select private production signing and a migration/distribution approach; store keys and passwords outside Git with a secure recovery copy.
- Update `pubspec.yaml` version/build number and write release notes describing tested scope and remaining limitations.
- Verify release-mode permissions, plugin behavior, upgrades, backups and restoration.
- Record commit, checksums, signing certificate identity and test evidence.
- Tag the accepted release and publish only explicitly approved artifacts. Store publication and cloud-service activation are separate actions.

The [work tracker](https://github.com/Shr1ramN/Dhara-Mitra/issues/20) is the completion checklist; a green CI badge alone is not release approval.
