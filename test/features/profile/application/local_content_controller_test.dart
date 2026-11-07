import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/contributor_entity.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/shared/local_content_controller.dart';
import 'package:github_news/core/shared/local_content_snapshots.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('should toggle local content and persist settings', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    final notifier = container.read(localContentControllerProvider.notifier);
    await notifier.toggleBookmark(_remoteRepo);
    await notifier.addMonitor(_remoteRepo);
    await notifier.toggleDeveloper(_remoteDeveloper);
    await notifier.setMonitorRule(2, true);

    final state = container.read(localContentControllerProvider);
    expect(state.isBookmarked(_remoteRepo.fullName), isTrue);
    expect(state.isMonitored(_remoteRepo.fullName), isTrue);
    expect(state.isFollowingDeveloper(_remoteDeveloper.login), isTrue);
    expect(state.monitorRules[2], isTrue);

    final restored = await _container();
    addTearDown(restored.dispose);
    final restoredState = restored.read(localContentControllerProvider);
    expect(restoredState.isBookmarked(_remoteRepo.fullName), isTrue);
    expect(restoredState.isMonitored(_remoteRepo.fullName), isTrue);
    expect(restoredState.isFollowingDeveloper(_remoteDeveloper.login), isTrue);
    expect(restoredState.monitorRules[2], isTrue);
  });

  test('restores complete snapshots for remote entities after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    final notifier = container.read(localContentControllerProvider.notifier);
    await notifier.toggleBookmark(_remoteRepo);
    await notifier.addMonitor(_remoteRepo);
    await notifier.toggleDeveloper(_remoteDeveloper);

    final restored = await _container();
    addTearDown(restored.dispose);
    final state = restored.read(localContentControllerProvider);

    expect(state.bookmarkedRepoSnapshots[_remoteRepo.fullName]?.description, _remoteRepo.description);
    expect(state.monitoredRepoSnapshots[_remoteRepo.fullName]?.language, _remoteRepo.language);
    expect(state.followedDeveloperSnapshots[_remoteDeveloper.login]?.contributions, _remoteDeveloper.contributions);
  });

  test('legacy ids without snapshots remain visible as minimal entities', () async {
    SharedPreferences.setMockInitialValues({
      'local_content_bookmarked_repos': ['legacy/unknown'],
      'local_content_monitored_repos': <String>[],
      'local_content_followed_developers': ['legacy-dev'],
    });
    final container = await _container();
    addTearDown(container.dispose);

    final state = container.read(localContentControllerProvider);

    expect(state.bookmarkedRepoSnapshots['legacy/unknown']?.fullName, 'legacy/unknown');
    expect(state.followedDeveloperSnapshots['legacy-dev']?.login, 'legacy-dev');
  });

  test('shared repo snapshot is deleted only after both collections remove it', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);
    final notifier = container.read(localContentControllerProvider.notifier);

    await notifier.toggleBookmark(_remoteRepo);
    await notifier.addMonitor(_remoteRepo);
    await notifier.removeBookmark(_remoteRepo.fullName);
    expect(container.read(localContentControllerProvider).repoSnapshots, contains(_remoteRepo.fullName));

    await notifier.removeMonitor(_remoteRepo.fullName);
    expect(container.read(localContentControllerProvider).repoSnapshots, isNot(contains(_remoteRepo.fullName)));
  });

  test('a corrupt snapshot payload is never overwritten by later edits', () async {
    const corrupt = '{not-json';
    SharedPreferences.setMockInitialValues({'local_content_repo_snapshots_v1': corrupt});
    final container = await _container();
    addTearDown(container.dispose);

    final notifier = container.read(localContentControllerProvider.notifier);
    await notifier.toggleBookmark(_remoteRepo);

    expect(container.read(localContentControllerProvider).isBookmarked(_remoteRepo.fullName), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('local_content_repo_snapshots_v1'), corrupt);
  });

  test('a partially corrupt snapshot payload keeps the original text until repaired', () async {
    final valid = SavedRepoSnapshot.minimal('ok/repo', DateTime.utc(2026, 1, 1)).toJson();
    final corrupt = jsonEncode([valid, {'broken': true}]);
    SharedPreferences.setMockInitialValues({'local_content_repo_snapshots_v1': corrupt});
    final container = await _container();
    addTearDown(container.dispose);

    await container.read(localContentControllerProvider.notifier).addMonitor(_remoteRepo);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('local_content_repo_snapshots_v1'), corrupt);
  });

  test('healthy snapshot payloads are still persisted normally', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    addTearDown(container.dispose);

    await container.read(localContentControllerProvider.notifier).toggleBookmark(_remoteRepo);

    final prefs = await SharedPreferences.getInstance();
    final restored = decodeRepoSnapshotsWithStatus(prefs.getString('local_content_repo_snapshots_v1'));
    expect(restored.corrupted, isFalse);
    expect(restored.values[_remoteRepo.fullName]?.description, _remoteRepo.description);
  });
}

const _remoteRepo = RepoEntity(fullName: 'remote/new-repo', description: 'Only returned by GitHub', language: 'Rust', starCount: 42, starDelta: 3, forkCount: 7, accentArgb: 0xFFDEA584);

const _remoteDeveloper = ContributorEntity(login: 'remote-dev', contributions: 19, avatarAccentArgb: 0xFF6366F1);

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}
