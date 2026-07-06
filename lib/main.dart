import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/storage/local_database.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait<dynamic>([
    SharedPreferences.getInstance(),
    LocalDatabase.open(),
  ]);
  final prefs = results[0] as SharedPreferences;
  final database = results[1] as LocalDatabase;
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const GitHubNewsApp(),
    ),
  );
}
