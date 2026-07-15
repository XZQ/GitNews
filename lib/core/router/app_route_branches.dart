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

List<StatefulShellBranch> buildAppRouteBranches() => [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const HomePage(),
            routes: [
              _repoDetailRoute('home_detail'),
              GoRoute(
                path: 'tech_hotspot_detail/:id',
                name: 'home_tech_hotspot_detail',
                builder: (_, state) => TechHotspotDetailPage(id: state.pathParameters['id']!),
              )
            ],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/ai_news',
            name: 'ai_news',
            builder: (_, __) => const AiNewsPage(),
            routes: [
              GoRoute(path: 'detail/:id', name: 'ai_news_detail', builder: (_, state) => AiNewsDetailPage(id: state.pathParameters['id']!)),
              GoRoute(
                path: 'webview',
                name: 'ai_news_webview',
                builder: (_, state) => WebViewPage(url: state.uri.queryParameters['url'] ?? '', title: state.uri.queryParameters['title']),
              ),
              // 资讯 → 仓库打通:详情页「相关仓库」跳转。
              // 不能复用 `detail/:fullName`,会与上面的资讯详情路由冲突。
              GoRoute(path: 'repo/:fullName', name: 'ai_news_repo_detail', builder: (_, state) => RepoDetailPage(fullName: state.pathParameters['fullName']!))
            ],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/trending',
            name: 'trending',
            builder: (_, __) => const TrendingPage(),
            routes: [
              GoRoute(path: 'overview', name: 'trending_overview', builder: (_, __) => const TrendingOverviewPage()),
              GoRoute(path: 'language', name: 'trending_language', builder: (_, __) => const LanguageTrendPage()),
              GoRoute(path: 'repos', name: 'trending_repos', builder: (_, __) => const HotReposPage()),
              _repoDetailRoute('trending_detail')
            ],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/tech_hotspot',
            name: 'tech_hotspot',
            builder: (_, __) => const TechHotspotPage(),
            routes: [GoRoute(path: 'detail/:id', name: 'tech_hotspot_detail', builder: (_, state) => TechHotspotDetailPage(id: state.pathParameters['id']!))],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (_, __) => const DiscoverHubPage(),
            routes: [_repoDetailRoute('discover_detail')],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/monitor',
            name: 'monitor',
            builder: (_, __) => const MonitorPage(),
            routes: [
              GoRoute(path: 'alerts', name: 'monitor_alerts', builder: (_, __) => const MonitorAlertsPage()),
              GoRoute(path: 'settings', name: 'monitor_settings', builder: (_, __) => const MonitorSettingsPage()),
              GoRoute(
                path: 'detail/:fullName',
                name: 'monitor_detail',
                builder: (_, state) => MonitorDetailPage(repoFullName: state.pathParameters['fullName']!),
              )
            ],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/project',
            name: 'project',
            builder: (_, __) => const ProjectPage(),
            routes: [
              GoRoute(path: 'explore', name: 'project_explore', builder: (_, __) => const ExplorePage()),
              GoRoute(path: 'activity', name: 'project_activity', builder: (_, __) => const ActivityPage()),
              GoRoute(path: 'discover', name: 'project_discover', builder: (_, __) => const DiscoverPage()),
              _repoDetailRoute('project_detail')
            ],
          )
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const ProfilePage(),
            routes: [
              GoRoute(path: 'login', name: 'profile_login', builder: (_, __) => const LoginPage()),
              GoRoute(path: 'collect', name: 'profile_collect', builder: (_, __) => const CollectPage()),
              GoRoute(path: 'developers', name: 'profile_developers', builder: (_, __) => const FollowedDevelopersPage()),
              GoRoute(path: 'monitor', name: 'profile_monitor', builder: (_, __) => const MonitorTopicsPage()),
              GoRoute(path: 'rules', name: 'profile_rules', builder: (_, __) => const MonitorRulesPage()),
              GoRoute(path: 'developer', name: 'profile_developer', builder: (_, __) => const DeveloperOptionsPage()),
              _repoDetailRoute('profile_detail')
            ],
          )
        ],
      )
    ];

GoRoute _repoDetailRoute(String name) {
  return GoRoute(path: 'detail/:fullName', name: name, builder: (_, state) => RepoDetailPage(fullName: state.pathParameters['fullName']!));
}
