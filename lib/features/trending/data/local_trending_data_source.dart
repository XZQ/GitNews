import '../../../core/demo_data.dart';
import '../../../core/demo_data_mappers.dart';
import '../domain/entities.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/* 
*基于内置种子数据的趋势数据源。
*保持与真实远端数据源相同的边界:先按查询条件取数,再交给 Repository
*组装页面 digest。
*/
class LocalTrendingDataSource implements TrendingDataSource {
  const LocalTrendingDataSource();

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    final trendingRepos = DemoData.trending.map((e) => e.toEntity()).toList();
    final recentRepos = DemoData.recent.map((e) => e.toEntity()).toList();

    return TrendingDataSnapshot(
      trendingRepos: _filterRepos(trendingRepos, query),
      recentRepos: _filterRepos(recentRepos, query),
      languages: DemoData.languages.map((e) => e.toEntity()).toList(),
      primaryTrend: const [],
      secondaryTrend: const [],
      tertiaryTrend: const [],
      topics: const [
        TrendingTopicEntity(name: 'ai-agents', repoCount: 4, starCount: 128000),
        TrendingTopicEntity(name: 'developer-tools', repoCount: 3, starCount: 96000),
        TrendingTopicEntity(name: 'rag', repoCount: 2, starCount: 64000),
        TrendingTopicEntity(name: 'llm', repoCount: 2, starCount: 58000),
      ],
    );
  }

  List<RepoEntity> _filterRepos(List<RepoEntity> repos, TrendingQuery query) {
    final language = query.language.trim().toLowerCase();
    return repos
        .where((repo) {
          if (!query.hasLanguageFilter) {
            return true;
          }
          return repo.language.trim().toLowerCase() == language;
        })
        .where((repo) => _matchesBoard(repo, query.board))
        .toList(growable: false);
  }

  bool _matchesBoard(RepoEntity repo, TrendingBoard board) {
    if (board == TrendingBoard.all) {
      return true;
    }
    final text = [repo.fullName, repo.description, repo.language].join(' ').toLowerCase();
    return switch (board) {
      TrendingBoard.all => true,
      TrendingBoard.agent => _containsAny(text, const ['agent', 'autogen', 'langgraph', 'crew', 'claude', 'codex']),
      TrendingBoard.mcp => _containsAny(text, const ['mcp', 'modelcontextprotocol', 'context protocol']),
      TrendingBoard.aiCoding => _containsAny(text, const ['coding', 'code', 'developer', 'editor', 'copilot', 'claude-code', 'codex']),
      TrendingBoard.newRepos => repo.starCount < 50000 || repo.starDelta > 400,
    };
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
