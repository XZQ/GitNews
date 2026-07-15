import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/i18n/app_localizations.dart';
import 'core/storage/cache_meta_dao.dart';
import 'core/storage/local_database.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_typography.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
typedef DatabaseOpener = Future<LocalDatabase> Function();
typedef DataDirectoryOpener = Future<bool> Function();
typedef BootstrapSuccessBuilder = Widget Function(BootstrapResult result);

class BootstrapResult {
  const BootstrapResult.success(this.preferences, this.database)
      : error = null,
        stackTrace = null;

  const BootstrapResult.failure(this.error, this.stackTrace)
      : preferences = null,
        database = null;

  final SharedPreferences? preferences;
  final LocalDatabase? database;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isSuccess => preferences != null && database != null;
}

Future<BootstrapResult> initializeApplication({SharedPreferencesLoader? sharedPreferencesLoader, DatabaseOpener? databaseOpener}) async {
  try {
    final preferences = await (sharedPreferencesLoader ?? SharedPreferences.getInstance)();
    final database = await (databaseOpener ?? LocalDatabase.open)();
    try {
      await CacheMetaDao(database.executor).pruneStale(now: DateTime.now(), retainFor: const Duration(days: 2));
    } catch (_) {
      // 缓存元数据清理是最佳努力，不阻断应用启动。
    }
    return BootstrapResult.success(preferences, database);
  } catch (error, stackTrace) {
    return BootstrapResult.failure(error, stackTrace);
  }
}

Future<bool> openApplicationDataDirectory() async {
  try {
    final directory = await getApplicationSupportDirectory();
    return launchUrl(Uri.directory(directory.path), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    this.initializer,
    this.openDataDirectory,
    this.successBuilder,
    super.key,
  });

  final Future<BootstrapResult> Function()? initializer;
  final DataDirectoryOpener? openDataDirectory;
  final BootstrapSuccessBuilder? successBuilder;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<BootstrapResult> _result;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _result = (widget.initializer ?? initializeApplication)();
  }

  void _retry() {
    setState(_start);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapResult>(
        future: _result,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result?.isSuccess ?? false) {
            if (widget.successBuilder case final successBuilder?) {
              return successBuilder(result!);
            }
            return ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(result!.preferences!), appDatabaseProvider.overrideWithValue(result.database!)], child: const GitHubNewsApp());
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootstrapShell(child: _BootstrapLoadingView());
          }
          final failure = result ?? BootstrapResult.failure(snapshot.error ?? StateError('Unknown bootstrap failure'), snapshot.stackTrace ?? StackTrace.empty);
          return _BootstrapShell(
              child: _BootstrapFailureView(
            result: failure,
            onRetry: _retry,
            openDataDirectory: widget.openDataDirectory ?? openApplicationDataDirectory,
          ));
        });
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(child: Semantics(label: AppLocalizations.of(context).tr('bootstrap.loading'), child: const CircularProgressIndicator()));
  }
}

class _BootstrapFailureView extends StatelessWidget {
  const _BootstrapFailureView({required this.result, required this.onRetry, required this.openDataDirectory});

  final BootstrapResult result;
  final VoidCallback onRetry;
  final DataDirectoryOpener openDataDirectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storage_rounded, size: 56, color: colors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.tr('bootstrap.failure.title'), style: AppTypography.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.tr('bootstrap.failure.message'), style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
              if (kDebugMode && result.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                SelectableText(result.error.toString(), style: AppTypography.labelSmall.copyWith(color: colors.error), textAlign: TextAlign.center)
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.restart_alt_rounded), label: Text(l10n.tr('bootstrap.retry'))),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _openDirectory(context),
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(l10n.tr('bootstrap.open_data_directory')),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirectory(BuildContext context) async {
    final opened = await openDataDirectory();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('bootstrap.open_failed'))));
    }
  }
}
