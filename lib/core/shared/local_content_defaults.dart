import '../demo_data.dart';
import '../demo_data_mappers.dart';
import '../domain/contributor_entity.dart';
import '../domain/repo_entity.dart';
import 'local_content_snapshots.dart';

final List<String> defaultBookmarkedRepos = [for (final repo in DemoData.trending.take(4)) repo.fullName];

final List<String> defaultMonitoredRepos = [for (final repo in DemoData.trending.take(4)) repo.fullName, for (final repo in DemoData.recent) repo.fullName];

final List<String> defaultFollowedDevelopers = {for (final contributor in DemoData.contributors) contributor.login}.toList();

final Map<String, RepoEntity> _defaultRepoSnapshots = {
  for (final repo in [...DemoData.trending, ...DemoData.recent]) repo.fullName: repo.toEntity()
};

final Map<String, ContributorEntity> _defaultDeveloperSnapshots = {for (final developer in DemoData.contributors) developer.login: developer.toEntity()};

Map<String, SavedRepoSnapshot> hydrateRepoSnapshots(Set<String> ids, Map<String, SavedRepoSnapshot> stored) {
  final now = DateTime.now();
  return {for (final id in ids) id: stored[id] ?? (_defaultRepoSnapshots[id] != null ? SavedRepoSnapshot.fromEntity(_defaultRepoSnapshots[id]!, now) : SavedRepoSnapshot.minimal(id, now))};
}

Map<String, SavedDeveloperSnapshot> hydrateDeveloperSnapshots(Set<String> ids, Map<String, SavedDeveloperSnapshot> stored) {
  final now = DateTime.now();
  return {
    for (final id in ids) id: stored[id] ?? (_defaultDeveloperSnapshots[id] != null ? SavedDeveloperSnapshot.fromEntity(_defaultDeveloperSnapshots[id]!, now) : SavedDeveloperSnapshot.minimal(id, now))
  };
}
