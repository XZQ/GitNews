import '../../../core/config/api_endpoints_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/github_api_support.dart';
import '../domain/discover_entities.dart';
import 'discover_queries.dart';

class DiscoverCacheCodec {
  const DiscoverCacheCodec._();

  static Map<String, Object?> repoListToJson(List<RepoEntity> repos) => {
        'items': [for (final repo in repos) _repoToJson(repo)]
      };

  static List<RepoEntity> decodeRepos(Map<String, Object?> json) => [for (final raw in GitHubJson.list(json['items'])) _repoFromJson(GitHubJson.map(raw))];

  static Map<String, Object?> skillsToJson(List<SkillEntity> skills) => {
        'items': [
          for (final skill in skills) {'repo': _repoToJson(skill.repo), 'category': skill.category, 'source': skill.source, 'rank': skill.rank, 'summary': skill.summary ?? ''}
        ]
      };

  static List<SkillEntity> decodeSkills(Map<String, Object?> json) => [for (final raw in GitHubJson.list(json['items'])) _skillFromJson(GitHubJson.map(raw))];

  static Map<String, Object?> profilesToJson(List<DiscoverProfileEntity> profiles) => {
        'items': [for (final profile in profiles) _profileToJson(profile)]
      };

  static List<DiscoverProfileEntity> decodeProfiles(Map<String, Object?> json, DiscoverProfileKind kind) =>
      [for (final raw in GitHubJson.list(json['items'])) profileFromJson(GitHubJson.map(raw), kind)];

  static RepoEntity repoFromGitHubSearch(Map<String, Object?> json) {
    final language = GitHubJson.nullableString(json['language']) ?? 'Unknown';
    return RepoEntity(
      fullName: GitHubJson.string(json['full_name']),
      description: GitHubJson.nullableString(json['description']) ?? 'No description',
      language: language,
      starCount: GitHubJson.intValue(json['stargazers_count']),
      starDelta: 0,
      forkCount: GitHubJson.intValue(json['forks_count']),
      accentArgb: GitHubApiSupport.languageColor(language),
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.estimated,
    );
  }

  static DiscoverProfileEntity profileFromJson(Map<String, Object?> json, DiscoverProfileKind kind) {
    final login = GitHubJson.string(json['login']);
    final name = GitHubJson.nullableString(json['name']);
    return DiscoverProfileEntity(
      login: login,
      name: (name == null || name.isEmpty) ? login : name,
      type: GitHubJson.nullableString(json['type']) ?? (kind == DiscoverProfileKind.official ? 'Organization' : 'User'),
      bio: GitHubJson.nullableString(json['bio']) ?? '',
      publicRepos: GitHubJson.intValue(json['public_repos'] ?? json['publicRepos']),
      followers: GitHubJson.intValue(json['followers']),
      avatarUrl: GitHubJson.nullableString(json['avatar_url']) ?? GitHubJson.nullableString(json['avatarUrl']) ?? '',
      htmlUrl: GitHubJson.nullableString(json['html_url']) ?? GitHubJson.nullableString(json['htmlUrl']) ?? '${ApiEndpointsConfig.githubWebBaseUrl}/$login',
      featuredRepoFullName: GitHubJson.nullableString(json['featuredRepoFullName']) ?? DiscoverQueries.featuredRepoForLogin(login),
      kind: kind,
      enriched: true,
      enrichFailed: false,
    );
  }

  static Map<String, Object?> _repoToJson(RepoEntity repo) => {
        'fullName': repo.fullName,
        'description': repo.description,
        'language': repo.language,
        'starCount': repo.starCount,
        'starDelta': repo.starDelta,
        'forkCount': repo.forkCount,
        'accentArgb': repo.accentArgb,
        'valueBasis': repo.valueBasis.name,
        'trendBasis': repo.trendBasis.name
      };

  static RepoEntity _repoFromJson(Map<String, Object?> json) => RepoEntity(
        fullName: GitHubJson.string(json['fullName']),
        description: GitHubJson.string(json['description']),
        language: GitHubJson.string(json['language']),
        starCount: GitHubJson.intValue(json['starCount']),
        starDelta: GitHubJson.intValue(json['starDelta']),
        forkCount: GitHubJson.intValue(json['forkCount']),
        accentArgb: GitHubJson.intValue(json['accentArgb']),
        valueBasis: _basisFromJson(json, 'valueBasis', 'valueProvenance'),
        trendBasis: _basisFromJson(json, 'trendBasis', 'trendProvenance'),
      );

  static SkillEntity _skillFromJson(Map<String, Object?> json) {
    return SkillEntity(
      repo: _repoFromJson(GitHubJson.map(json['repo'])),
      category: GitHubJson.string(json['category']),
      source: GitHubJson.string(json['source']),
      rank: GitHubJson.intValue(json['rank']),
      summary: GitHubJson.nullableString(json['summary']),
    );
  }

  static MetricBasis _basisFromJson(Map<String, Object?> json, String key, String legacyKey) {
    final name = GitHubJson.nullableString(json[key]);
    return name == null ? MetricBasis.fromLegacyName(GitHubJson.nullableString(json[legacyKey])) : MetricBasis.fromName(name);
  }

  static Map<String, Object?> _profileToJson(DiscoverProfileEntity profile) => {
        'login': profile.login,
        'name': profile.name,
        'type': profile.type,
        'bio': profile.bio,
        'publicRepos': profile.publicRepos,
        'followers': profile.followers,
        'avatarUrl': profile.avatarUrl,
        'htmlUrl': profile.htmlUrl,
        'featuredRepoFullName': profile.featuredRepoFullName,
        'enriched': profile.enriched,
        'enrichFailed': profile.enrichFailed
      };
}
