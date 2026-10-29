import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import 'account_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.settings = false});
  final bool settings;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _emailMode = false, _register = false, _reset = false;
  bool _busy = false, _obscured = true;
  String? _message;
  AccountController? _listeningAccount;

  @override
  void initState() {
    super.initState();
    _listeningAccount = ref.read(accountControllerProvider);
    _listeningAccount?.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _listeningAccount?.removeListener(_accountChanged);
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final message = await action();
      if (mounted) setState(() => _message = message);
    } catch (_) {
      if (mounted) setState(() => _message = context.l.aRequestFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _local(AccountController account, {bool restore = false}) async {
    final l = context.l;
    var accepted = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.aLocalMode),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.aLocalWarning),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: accepted,
                  title: Text(l.aAcknowledge),
                  onChanged: (value) =>
                      setDialogState(() => accepted = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: accepted ? () => Navigator.pop(context, true) : null,
              child: Text(l.aLocal),
            ),
          ],
        ),
      ),
    );
    if (proceed == true) {
      account.openBackup = restore;
      await _run(() async {
        await account.continueLocally();
        return null;
      });
    }
  }

  Future<void> _submit(AccountController account) async {
    if (!_form.currentState!.validate()) return;
    final l = context.l;
    await _run(() async {
      if (account.recovering) {
        await account.updatePassword(_password.text);
      } else if (_reset) {
        await account.resetPassword(_email.text);
        return l.aResetSent;
      } else if (_register) {
        final signedIn = await account.signUp(_email.text, _password.text);
        if (!signedIn) return l.aVerifyEmail;
      } else {
        try {
          await account.signIn(_email.text, _password.text);
        } catch (_) {
          return l.aAuthFailed;
        }
      }
      return null;
    });
  }

  void _mode({bool email = true, bool register = false, bool reset = false}) {
    setState(() {
      _emailMode = email;
      _register = register;
      _reset = reset;
      _message = null;
      _password.clear();
      _confirmation.clear();
      _form.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountControllerProvider);
    final l = context.l;
    if (account == null) {
      return Scaffold(appBar: AppBar(title: Text(l.aAccount)));
    }
    final recovery = account.recovering;
    final configured = account.client != null;
    final signedIn = account.user != null && !recovery;
    final emailForm = _emailMode || recovery;
    final newPassword = _register || recovery;
    return Scaffold(
      appBar: AppBar(title: Text(widget.settings ? l.aAccount : l.appName)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Image.asset('assets/branding/logo.png', width: 56, height: 56),
                const SizedBox(height: 16),
                Text(
                  recovery
                      ? l.aNewPassword
                      : signedIn
                      ? l.aAccount
                      : account.local && widget.settings
                      ? l.aLocalMode
                      : l.aWelcome,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (!signedIn && !recovery) ...[
                  Text(l.aChooseMode),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'kn', label: Text('ಕನ್ನಡ')),
                    ],
                    selected: {Localizations.localeOf(context).languageCode},
                    onSelectionChanged: _busy
                        ? null
                        : (values) async {
                            await account.setLanguage(values.first);
                            if (context.mounted && widget.settings) {
                              // Settings uses the existing farm's locale provider.
                              await ref
                                  .read(localeProvider.notifier)
                                  .set(values.first);
                            }
                          },
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.aManualBackup),
                  ),
                ),
                const SizedBox(height: 12),
                if (signedIn) ...[
                  Text(
                    account.user!.email ?? l.aAccount,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(l.aSignOutInfo),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await account.signOut();
                            return null;
                          }),
                    child: Text(l.aSignOut),
                  ),
                ] else ...[
                  if (!configured)
                    Text(
                      account.configurationFailed
                          ? l.aUnavailable
                          : l.aNotConfigured,
                    ),
                  if (account.authError) Text(l.aUnavailable),
                  if (!recovery) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.login),
                      onPressed: !configured || _busy
                          ? null
                          : () => _run(() async {
                              await account.google();
                              return l.aBrowserOpened;
                            }),
                      label: Text(l.aGoogle),
                    ),
                    const SizedBox(height: 8),
                    if (!emailForm)
                      OutlinedButton(
                        onPressed: !configured || _busy ? null : () => _mode(),
                        child: Text(l.aEmail),
                      ),
                  ],
                  if (emailForm)
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!recovery)
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              decoration: InputDecoration(
                                labelText: l.aEmailAddress,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) =>
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value?.trim() ?? '')
                                  ? null
                                  : l.aInvalidEmail,
                            ),
                          if (!_reset || recovery) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _obscured,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: [
                                newPassword
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: recovery
                                    ? l.aNewPassword
                                    : l.aPassword,
                                suffixIcon: IconButton(
                                  tooltip: _obscured
                                      ? l.aShowPassword
                                      : l.aHidePassword,
                                  onPressed: () =>
                                      setState(() => _obscured = !_obscured),
                                  icon: Icon(
                                    _obscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? l.aPasswordRequired
                                  : newPassword && value!.length < 8
                                  ? l.aPasswordLength
                                  : null,
                            ),
                            if (newPassword) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmation,
                                enabled: !_busy,
                                obscureText: _obscured,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: InputDecoration(
                                  labelText: l.aConfirmPassword,
                                ),
                                validator: (value) => value == _password.text
                                    ? null
                                    : l.aPasswordMismatch,
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy || !configured
                                ? null
                                : () => _submit(account),
                            child: Text(
                              recovery
                                  ? l.aSavePassword
                                  : _reset
                                  ? l.aSendReset
                                  : _register
                                  ? l.aCreateAccount
                                  : l.aSignIn,
                            ),
                          ),
                          if (!recovery) ...[
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _mode(register: !_register),
                              child: Text(
                                _register || _reset
                                    ? l.aSignIn
                                    : l.aCreateAccount,
                              ),
                            ),
                            if (!_reset)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _mode(reset: true),
                                child: Text(l.aForgotPassword),
                              ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _mode(email: false),
                              child: Text(l.aBack),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (recovery)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await account.signOut();
                              return null;
                            }),
                      child: Text(l.aCancelRecovery),
                    )
                  else ...[
                    if (!account.local) ...[
                      OutlinedButton(
                        onPressed: _busy ? null : () => _local(account),
                        child: Text(l.aLocal),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _local(account, restore: true),
                        child: Text(l.aRestoreLocal),
                      ),
                    ] else
                      Text(l.aLocalWarning),
                    const SizedBox(height: 16),
                    Text(l.aSeparateRecords),
                  ],
                ],
                if (widget.settings)
                  TextButton.icon(
                    onPressed: _busy ? null : () => context.push('/backup'),
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(l.aBackupRestore),
                  ),
                if (_busy) const Center(child: CircularProgressIndicator()),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(liveRegion: true, child: Text(_message!)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
