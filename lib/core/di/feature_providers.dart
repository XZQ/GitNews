// DI barrel export — 聚合各 feature 核心 Provider,方便测试时 override。
// 此文件只做 re-export,不定义新 Provider。各 feature 的 Provider
// 仍在各自的 `application/` 目录下定义,此处统一导出以便:
// 1. 新人快速了解全项目的依赖注入点
// 2. 测试时从此处 import 并 override
library;

// features
export '../../features/ai_news/application/ai_news_providers.dart';
export '../../features/discover/application/discover_providers.dart';
export '../../features/monitor/application/monitor_providers.dart';
export '../../features/project/application/project_providers.dart';
export '../../features/repo_detail/application/repo_detail_providers.dart';
export '../../features/tech_hotspot/application/tech_hotspot_providers.dart';
export '../../features/trending/application/trending_providers.dart';
// TODO(xzq): create theme_controller.dart.
// export '../preferences/theme_controller.dart'
//     show themeModeProvider, themePresetProvider;
// TODO(xzq): create sidebar_width_controller.dart.
// export '../preferences/sidebar_width_controller.dart'
//     show sidebarWidthProvider;
export '../github/rate_limit_gate.dart' show rateLimitGateProvider, RateLimitGateStatus;
// core
export '../network/dio_client.dart' show DioClient;
export '../preferences/github_token_controller.dart' show githubTokenControllerProvider, GitHubTokenState, GitHubTokenController;
export '../storage/storage_providers.dart' show appDatabaseProvider;
export 'project_composition.dart';
export 'providers.dart' show dioProvider, sharedPreferencesProvider, secureStorageProvider;
