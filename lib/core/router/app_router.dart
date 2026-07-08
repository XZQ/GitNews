import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_news/presentation/ai_news_detail_page.dart';
import '../../features/ai_news/presentation/ai_news_page.dart';
import '../../features/discover/presentation/discover_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/monitor/presentation/monitor_alerts_page.dart';
import '../../features/monitor/presentation/monitor_detail_page.dart';
import '../../features/monitor/presentation/monitor_page.dart';
import '../../features/monitor/presentation/monitor_settings_page.dart';
import '../../features/profile/presentation/collect_page.dart';
import '../../features/profile/presentation/developer_options_page.dart';
import '../../features/profile/presentation/followed_developers_page.dart';
import '../../features/profile/presentation/login_page.dart';
import '../../features/profile/presentation/monitor_rules_page.dart';
import '../../features/profile/presentation/monitor_topics_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/project/presentation/activity_page.dart';
import '../../features/project/presentation/discover_page.dart';
import '../../features/project/presentation/explore_page.dart';
import '../../features/project/presentation/project_page.dart';
import '../../features/repo_detail/presentation/repo_detail_page.dart';
import '../../features/tech_hotspot/presentation/tech_hotspot_detail_page.dart';
import '../../features/tech_hotspot/presentation/tech_hotspot_page.dart';
import '../../features/trending/presentation/hot_repos_page.dart';
import '../../features/trending/presentation/language_trend_page.dart';
import '../../features/trending/presentation/trending_overview_page.dart';
import '../../features/trending/presentation/trending_page.dart';
import '../../features/webview/presentation/webview_page.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../preferences/startup_tab_controller.dart';
import 'route_error_view.dart';

export 'route_specs.dart';

// 应用根路由。
// 设计要点(对应 CLAUDE.md §九):
// - 使用普通 [Provider]:当前路由不依赖任何外部状态(登录态接入后可
// 切回 NotifierProvider 并在 build 内 `ref.watch` 鉴权 Provider)。
// - 未匹配路由由 [RouteErrorView] 静态展示错误页,而非跳转首页,以便
// 用户能识别深链失效的原因。
final appRouterProvider = Provider<GoRouter>(buildAppRouter);

/* 
*应用根路由装配。
*登录态接入后,若路由依赖外部状态,改回 NotifierProvider 并在 build 内
*`ref.watch` 鉴权 Provider。
*/
GoRouter buildAppRouter(Ref ref) {
  // 启动 Tab 偏好:ref.read 一次,下次冷启动生效(不 watch,避免热重建路由栈)。
  final startupSegment = ref.read(startupTabControllerProvider);
  return GoRouter(
    initialLocation: '/$startupSegment',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ResponsiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (_, __) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'home_detail',
                    builder: (_, state) => RepoDetailPage(
                      fullName: state.pathParameters['fullName']!,
                    ),
                  ),
                  GoRoute(
                    path: 'tech_hotspot_detail/:id',
                    name: 'home_tech_hotspot_detail',
                    builder: (_, state) =>
                        TechHotspotDetailPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai_news',
                name: 'ai_news',
                builder: (_, __) => const AiNewsPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'ai_news_detail',
                    builder: (_, state) =>
                        AiNewsDetailPage(id: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'webview',
                    name: 'ai_news_webview',
                    builder: (_, state) {
                      final url = state.uri.queryParameters['url'] ?? '';
                      final title = state.uri.queryParameters['title'];
                      return WebViewPage(url: url, title: title);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trending',
                name: 'trending',
                builder: (_, __) => const TrendingPage(),
                routes: [
                  GoRoute(
                    path: 'overview',
                    name: 'trending_overview',
                    builder: (_, __) => const TrendingOverviewPage(),
                  ),
                  GoRoute(
                    path: 'language',
                    name: 'trending_language',
                    builder: (_, __) => const LanguageTrendPage(),
                  ),
                  GoRoute(
                    path: 'repos',
                    name: 'trending_repos',
                    builder: (_, __) => const HotReposPage(),
                  ),
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'trending_detail',
                    builder: (_, state) => RepoDetailPage(
                      fullName: state.pathParameters['fullName']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tech_hotspot',
                name: 'tech_hotspot',
                builder: (_, __) => const TechHotspotPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: 'tech_hotspot_detail',
                    builder: (_, state) =>
                        TechHotspotDetailPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: 'discover',
                builder: (_, __) => const DiscoverHubPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'discover_detail',
                    builder: (_, state) => RepoDetailPage(
                      fullName: state.pathParameters['fullName']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/monitor',
                name: 'monitor',
                builder: (_, __) => const MonitorPage(),
                routes: [
                  GoRoute(
                    path: 'alerts',
                    name: 'monitor_alerts',
                    builder: (_, __) => const MonitorAlertsPage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'monitor_settings',
                    builder: (_, __) => const MonitorSettingsPage(),
                  ),
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'monitor_detail',
                    builder: (_, state) => MonitorDetailPage(
                      repoFullName: state.pathParameters['fullName']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/project',
                name: 'project',
                builder: (_, __) => const ProjectPage(),
                routes: [
                  GoRoute(
                    path: 'explore',
                    name: 'project_explore',
                    builder: (_, __) => const ExplorePage(),
                  ),
                  GoRoute(
                    path: 'activity',
                    name: 'project_activity',
                    builder: (_, __) => const ActivityPage(),
                  ),
                  GoRoute(
                    path: 'discover',
                    name: 'project_discover',
                    builder: (_, __) => const DiscoverPage(),
                  ),
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'project_detail',
                    builder: (_, state) => RepoDetailPage(
                      fullName: state.pathParameters['fullName']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (_, __) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'login',
                    name: 'profile_login',
                    builder: (_, __) => const LoginPage(),
                  ),
                  GoRoute(
                    path: 'collect',
                    name: 'profile_collect',
                    builder: (_, __) => const CollectPage(),
                  ),
                  GoRoute(
                    path: 'developers',
                    name: 'profile_developers',
                    builder: (_, __) => const FollowedDevelopersPage(),
                  ),
                  GoRoute(
                    path: 'monitor',
                    name: 'profile_monitor',
                    builder: (_, __) => const MonitorTopicsPage(),
                  ),
                  GoRoute(
                    path: 'rules',
                    name: 'profile_rules',
                    builder: (_, __) => const MonitorRulesPage(),
                  ),
                  GoRoute(
                    path: 'developer',
                    name: 'profile_developer',
                    builder: (_, __) => const DeveloperOptionsPage(),
                  ),
                  GoRoute(
                    path: 'detail/:fullName',
                    name: 'profile_detail',
                    builder: (_, state) => RepoDetailPage(
                      fullName: state.pathParameters['fullName']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // 全局登录
      GoRoute(
        path: '/login',
        name: 'login',
        redirect: (_, __) => '/profile/login',
      ),
      // 全局应用内 WebView:仅保留给非 Tab 场景。Tab 内链接应优先放在
      // 对应分支的子路由里,避免桌面端绕开侧栏和 B 区域。
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (_, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'];
          return WebViewPage(url: url, title: title);
        },
      ),
    ],
    errorBuilder: (context, state) => RouteErrorView(error: state.error),
  );
}
