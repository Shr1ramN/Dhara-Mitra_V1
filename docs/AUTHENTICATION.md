# Sign-in setup (phase one)

The Android app supports Google OAuth, email/password registration and sign-in,
email confirmation, password recovery, and local use without an account. It uses
Supabase Auth, matching the planned cloud backend. Cloud backup is still deferred.
Signing in does **not** upload farm records or protect them against device loss.

## Configure an Android build

1. Use a Supabase project. Enable the Email provider and **Confirm email** in
   Authentication. Set a password policy of at least eight characters. Configure
   an SMTP sender for real users and customize confirmation/recovery templates
   with Dhara Mitra's name.
2. Enable the Google provider in Supabase. Create a Google OAuth web client,
   configure its consent screen and authorized users, and add the Supabase callback
   URL shown in the provider settings to Google's authorized redirect URIs. Store
   the Google client ID and secret in Supabase's provider settings.
3. Add `in.dharamitra://auth/callback` to Supabase Authentication's allowed redirect
   URLs. The Android manifest routes this callback to the app. Flutter's own
   deep-link routing is disabled. AccountController attaches its link handler after
   its auth listener so password recovery also works on a cold start.
4. Build or run with the project URL and public publishable key:

   ```powershell
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
   ```

   Use the same defines with `flutter build apk`. Never use a Supabase service-role
   key or Google client secret in the app. Keep those in the server/dashboard.

Without configuration, Google/email buttons are disabled with an explanation.
Local use, backup and restore remain available. This implementation targets Android;
other platforms need their own callback registration before use.

## Data and session behavior

- First launch offers Google, email/password, and local mode. Local mode requires
  acknowledging the data-loss warning. The choice persists across restarts.
- Existing installations keep their legacy local farm database and catalogue.
  Select local mode to access those records after upgrading.
- Each account has a separate catalogue and newly generated farm profile IDs.
  Switching accounts never automatically assigns farms to another account.
  To move local records, export **all farms** in local mode, sign in through
  **More → Account**, then import that ZIP through **Backup and restore**. Import
  creates new farm profiles and includes attachments.
- Supabase session state, account choice, and welcome-screen language live outside
  farm databases and exported backups. Restoring a backup cannot sign into an account.
- Returning users can use cached records offline. Creating an account,
  Google/email sign-in and password changes require connectivity.
- **More → Account** shows the account, backup warning, backup shortcut and sign-out.
  Signing out retains farm files; signing into the same account reopens its catalogue.
  Background refresh uses the active catalogue; scheduled alerts from the catalogue
  being signed out are cancelled.
- Open confirmation and password-reset links on the device that requested them
  (the SDK uses PKCE). Recovery displays a new-password form.
- A new phone has no farm records until a manual backup is imported. Phase two
  will add account-linked cloud backup and restore.

## Verification

Automated tests cover the local warning and acknowledgement, missing configuration,
email/password validation, confirmation messaging, reset requests, Kannada strings,
and catalogue isolation/preservation. Live acceptance needs a configured Supabase
project and Android device:

- Google sign-in, browser cancellation/retry, and app return through the callback.
- Email registration/confirmation, wrong password, and password recovery while
  running and after a cold start.
- Offline restart after signing in or choosing local mode.
- Sign out, switch accounts, and return to the original account.
- Export local farms/attachments, import into an account, and verify the local
  originals and the other account's records remain unchanged.

References: [Supabase Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[OAuth sign-in](https://supabase.com/docs/reference/dart/auth-signinwithoauth).
