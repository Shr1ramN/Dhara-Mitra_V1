import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/farm_profiles.dart';
import 'core/farm_host.dart';
import 'core/v1.dart';
import 'features/auth/account_controller.dart';
import 'features/auth/account_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final catalogue = await FarmProfiles.onDevice();
  if (v1) {
    final owner = (await SharedPreferences.getInstance()).getString(
      'account.activeOwner',
    );
    final offlineCatalogue =
        owner != null &&
            owner != 'local' &&
            owner != 'default' &&
            FarmProfiles.validId(owner)
        ? FarmProfiles(catalogue.root, ownerId: owner)
        : catalogue;
    final active = (await offlineCatalogue.read()).active;
    runApp(
      FarmHost(
        initial: await FarmSession.open(active),
        catalogue: offlineCatalogue,
      ),
    );
    return;
  }
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? client;
  var configurationFailed = false;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: key,
        authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      );
      client = Supabase.instance.client;
    } catch (_) {
      configurationFailed = true;
    }
  }
  final account = AccountController(
    await SharedPreferences.getInstance(),
    client: client,
    configurationFailed: configurationFailed,
  );
  await account.initialize();
  await account.startLinkHandling();
  runApp(AccountHost(controller: account, localCatalogue: catalogue));
}
