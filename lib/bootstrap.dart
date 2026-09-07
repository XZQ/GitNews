import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'core/auth/auth_models.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/supabase_auth_repository.dart';
import 'core/di/provider_retry_policy.dart';
import 'core/di/providers.dart';
import 'core/i18n/app_localizations.dart';
import 'core/platform/startup_probe.dart';
import 'core/storage/cache_meta_dao.dart';
import 'core/storage/local_database.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_typography.dart';
import 'shared/widgets/window_title_bar.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
typedef DatabaseOpener = Future<LocalDatabase> Function();
typedef AuthRepositoryLoader = Future<AuthRepository> Function(FlutterSecureStorage storage);
typedef DataDirectoryOpener = Future<bool> Function();
typedef BootstrapSuccessBuilder = Widget Function(BootstrapResult result);

class BootstrapResult {
  const BootstrapResult.success(this.preferences, this.database, [this.authRepository = const UnconfiguredAuthRepository()]) : error = null, stackTrace = null;

  const BootstrapResult.failure(this.error, this.stackTrace) : preferences = null, database = null, authRepository = const UnconfiguredAuthRepository();

  final SharedPreferences? preferences;
  final LocalDatabase? database;
  final AuthRepository authRepository;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isSuccess => preferences != null && database != null;
}

Future<BootstrapResult> initializeApplication({SharedPreferencesLoader? sharedPreferencesLoader, DatabaseOpener? databaseOpener, AuthRepositoryLoader? authRepositoryLoader}) async {
  // 三项初始化互不依赖,同时启动并行执行缩短冷启动;错误类型与串行版保持一致。
  LocalDatabase? openedDatabase;
  final preferencesFuture = (sharedPreferencesLoader ?? SharedPreferences.getInstance)();
  final databaseFuture = (databaseOpener ?? LocalDatabase.open)().then<LocalDatabase>((db) => openedDatabase = db);
  final authFuture = _openAuthRepository(authRepositoryLoader);
  // prefs 失败时 databaseFuture 不再被 await,预挂兜底监听避免晚到的错误成为未处理异步错误。
  databaseFuture.ignore();
  try {
    final preferences = await preferencesFuture;
    final database = await databaseFuture;
    final authRepository = await authFuture;
    // 在接受初始化结果前验证主资讯表可读，损坏/不完整迁移进入恢复页。
    await database.executor.rawQuery('SELECT COUNT(*) AS item_count FROM ai_news_item');
    try {
      await CacheMetaDao(database.executor).pruneStale(now: DateTime.now(), retainFor: const Duration(days: 2));
    } catch (_) {
      // 缓存元数据清理是最佳努力，不阻断应用启动。
    }
    return BootstrapResult.success(preferences, database, authRepository);
  } catch (error, stackTrace) {
    // prefs 先失败时数据库可能仍在打开中;等它落定后再关闭,避免 sqlite 连接泄漏。
    // 错误已被上方 ignore() 吞掉,这里的 await 不会再抛。
    try {
      await databaseFuture;
    } catch (_) {
      // 打开失败无需清理。
    }
    try {
      await openedDatabase?.close();
    } catch (_) {
      // 关闭失败不掩盖原始启动错误。
    }
    return BootstrapResult.failure(error, stackTrace);
  }
}

// 认证初始化独立兜底:失败降级为不可用仓库,不阻断本地优先启动。
Future<AuthRepository> _openAuthRepository(AuthRepositoryLoader? loader) async {
  try {
    return await (loader ?? initializeAuthRepository)(defaultSecureStorage);
  } catch (_) {
    return const UnavailableAuthRepository(AuthCapabilities(isConfigured: true));
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
  const BootstrapApp({this.initializer, this.openDataDirectory, this.successBuilder, this.startupReporter = reportStartupProbe, super.key});

  final Future<BootstrapResult> Function()? initializer;
  final DataDirectoryOpener? openDataDirectory;
  final BootstrapSuccessBuilder? successBuilder;
  // 只有成功主壳的首帧完成后才能报告 ready；失败页永不报告就绪。
  final StartupReporter startupReporter;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<BootstrapResult> _result;
  bool _readyScheduled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _readyScheduled = false;
    _result = _initializeAndReport();
  }

  /* 把初始化的真实结果交给受控探针，保留恢复页面的重试路径。 */
  Future<BootstrapResult> _initializeAndReport() async {
    await widget.startupReporter('initializing');
    BootstrapResult result;
    try {
      result = await (widget.initializer ?? initializeApplication)();
    } catch (error, stack) {
      result = BootstrapResult.failure(error, stack);
    }
    if (!result.isSuccess) {
      await widget.startupReporter('failed', error: result.error);
    }
    return result;
  }

  /* 等待成功页面绘制，再为本次启动报告就绪。 */
  void _reportReadyAfterFrame() {
    if (_readyScheduled) {
      return;
    }
    _readyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await widget.startupReporter('ready');
      }
    });
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
          _reportReadyAfterFrame();
          if (widget.successBuilder case final successBuilder?) {
            return successBuilder(result!);
          }
          return ProviderScope(
            retry: noProviderRetry,
            overrides: [
              sharedPreferencesProvider.overrideWithValue(result!.preferences!),
              appDatabaseProvider.overrideWithValue(result.database!),
              authRepositoryProvider.overrideWithValue(result.authRepository),
            ],
            child: const GitHubNewsApp(),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapShell(child: _BootstrapLoadingView());
        }
        final failure = result ?? BootstrapResult.failure(snapshot.error ?? StateError('Unknown bootstrap failure'), snapshot.stackTrace ?? StackTrace.empty);
        return _BootstrapShell(
          child: _BootstrapFailureView(result: failure, onRetry: _retry, openDataDirectory: widget.openDataDirectory ?? openApplicationDataDirectory),
        );
      },
    );
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
      home: DesktopWindowFrame(child: Scaffold(body: child)),
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(label: AppLocalizations.of(context).tr('bootstrap.loading'), child: const CircularProgressIndicator()),
    );
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
              Text(
                l10n.tr('bootstrap.failure.message'),
                style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode && result.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  result.error.toString(),
                  style: AppTypography.labelSmall.copyWith(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.restart_alt_rounded), label: Text(l10n.tr('bootstrap.retry'))),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(onPressed: () => _openDirectory(context), icon: const Icon(Icons.folder_open_rounded), label: Text(l10n.tr('bootstrap.open_data_directory'))),
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
