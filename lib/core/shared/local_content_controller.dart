import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../domain/contributor_entity.dart';
import '../domain/repo_entity.dart';
import '../i18n/app_localizations.dart';
import 'local_content_defaults.dart';
import 'local_content_snapshots.dart';

const int monitorRuleCount = 4;

List<String> monitorRuleLabels(AppLocalizations l10n) =>
    [l10n.tr('monitor.rule.star_growth'), l10n.tr('monitor.rule.daily_growth'), l10n.tr('monitor.rule.fork_growth'), l10n.tr('monitor.rule.discuss_heat')];

class LocalContentState {
  const LocalContentState(
      {required this.bookmarkedRepos,
      required this.monitoredRepos,
      required this.monitoredSkills,
      required this.followedDevelopers,
      required this.monitorRules,
      required this.repoSnapshots,
      required this.developerSnapshots,
      this.cachedUserName,
      this.cachedAvatarUrl});

  final Set<String> bookmarkedRepos;
  final Set<String> monitoredRepos;
  final Set<String> monitoredSkills;
  final Set<String> followedDevelopers;
  final List<bool> monitorRules;
  final Map<String, SavedRepoSnapshot> repoSnapshots;
  final Map<String, SavedDeveloperSnapshot> developerSnapshots;
  final String? cachedUserName;
  final String? cachedAvatarUrl;

  int get enabledRuleCount => monitorRules.where((enabled) => enabled).length;

  bool isBookmarked(String fullName) => bookmarkedRepos.contains(fullName);

  bool isMonitored(String fullName) => monitoredRepos.contains(fullName);

  bool isMonitoredSkill(String fullName) => monitoredSkills.contains(fullName);

  bool isFollowingDeveloper(String login) => followedDevelopers.contains(login);

  Map<String, SavedRepoSnapshot> get bookmarkedRepoSnapshots => {
        for (final id in bookmarkedRepos)
          if (repoSnapshots[id] case final snapshot?) id: snapshot
      };

  Map<String, SavedRepoSnapshot> get monitoredRepoSnapshots => {
        for (final id in monitoredRepos)
          if (repoSnapshots[id] case final snapshot?) id: snapshot
      };

  Map<String, SavedDeveloperSnapshot> get followedDeveloperSnapshots => {
        for (final id in followedDevelopers)
          if (developerSnapshots[id] case final snapshot?) id: snapshot
      };

  LocalContentState copyWith(
      {Set<String>? bookmarkedRepos,
      Set<String>? monitoredRepos,
      Set<String>? monitoredSkills,
      Set<String>? followedDevelopers,
      List<bool>? monitorRules,
      Map<String, SavedRepoSnapshot>? repoSnapshots,
      Map<String, SavedDeveloperSnapshot>? developerSnapshots,
      String? cachedUserName,
      String? cachedAvatarUrl,
      bool clearCachedUser = false}) {
    return LocalContentState(
      bookmarkedRepos: bookmarkedRepos ?? this.bookmarkedRepos,
      monitoredRepos: monitoredRepos ?? this.monitoredRepos,
      monitoredSkills: monitoredSkills ?? this.monitoredSkills,
      followedDevelopers: followedDevelopers ?? this.followedDevelopers,
      monitorRules: monitorRules ?? this.monitorRules,
      repoSnapshots: repoSnapshots ?? this.repoSnapshots,
      developerSnapshots: developerSnapshots ?? this.developerSnapshots,
      cachedUserName: clearCachedUser ? null : (cachedUserName ?? this.cachedUserName),
      cachedAvatarUrl: clearCachedUser ? null : (cachedAvatarUrl ?? this.cachedAvatarUrl),
    );
  }
}

class LocalContentController extends Notifier<LocalContentState> {
  static const _bookmarksKey = 'local_content_bookmarked_repos';
  static const _monitorsKey = 'local_content_monitored_repos';
  static const _skillsKey = 'local_content_monitored_skills';
  static const _developersKey = 'local_content_followed_developers';
  static const _rulesKey = 'local_content_monitor_rules';
  static const _userNameKey = 'local_content_cached_user_name';
  static const _userAvatarKey = 'local_content_cached_user_avatar';
  static const _repoSnapshotsKey = 'local_content_repo_snapshots_v1';
  static const _developerSnapshotsKey = 'local_content_developer_snapshots_v1';

  @override
  LocalContentState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final bookmarks = _readSet(prefs.getStringList(_bookmarksKey), defaultBookmarkedRepos);
    final monitors = _readSet(prefs.getStringList(_monitorsKey), defaultMonitoredRepos);
    final developers = _readSet(prefs.getStringList(_developersKey), defaultFollowedDevelopers);
    return LocalContentState(
      bookmarkedRepos: bookmarks,
      monitoredRepos: monitors,
      monitoredSkills: _readSet(prefs.getStringList(_skillsKey), const []),
      followedDevelopers: developers,
      monitorRules: _readRules(prefs.getStringList(_rulesKey)),
      repoSnapshots: hydrateRepoSnapshots({...bookmarks, ...monitors}, decodeRepoSnapshots(prefs.getString(_repoSnapshotsKey))),
      developerSnapshots: hydrateDeveloperSnapshots(developers, decodeDeveloperSnapshots(prefs.getString(_developerSnapshotsKey))),
      cachedUserName: prefs.getString(_userNameKey),
      cachedAvatarUrl: prefs.getString(_userAvatarKey),
    );
  }

  Future<void> toggleBookmark(RepoEntity repo) async {
    final fullName = repo.fullName;
    final next = {...state.bookmarkedRepos};
    final snapshots = {...state.repoSnapshots};
    if (next.add(fullName)) {
      snapshots[fullName] = SavedRepoSnapshot.fromEntity(repo, DateTime.now());
    } else {
      next.remove(fullName);
      if (!state.monitoredRepos.contains(fullName)) {
        snapshots.remove(fullName);
      }
    }
    state = state.copyWith(bookmarkedRepos: next, repoSnapshots: snapshots);
    await _persistSet(_bookmarksKey, next);
    await _persistRepoSnapshots(snapshots);
  }

  Future<void> removeBookmark(String fullName) async {
    final next = {...state.bookmarkedRepos}..remove(fullName);
    final snapshots = {...state.repoSnapshots};
    if (!state.monitoredRepos.contains(fullName)) {
      snapshots.remove(fullName);
    }
    state = state.copyWith(bookmarkedRepos: next, repoSnapshots: snapshots);
    await _persistSet(_bookmarksKey, next);
    await _persistRepoSnapshots(snapshots);
  }

  Future<void> addMonitor(RepoEntity repo) async {
    final fullName = repo.fullName;
    final next = {...state.monitoredRepos, fullName};
    final snapshots = {...state.repoSnapshots}..[fullName] = SavedRepoSnapshot.fromEntity(repo, DateTime.now());
    state = state.copyWith(monitoredRepos: next, repoSnapshots: snapshots);
    await _persistSet(_monitorsKey, next);
    await _persistRepoSnapshots(snapshots);
  }

  Future<void> removeMonitor(String fullName) async {
    final next = {...state.monitoredRepos}..remove(fullName);
    final snapshots = {...state.repoSnapshots};
    if (!state.bookmarkedRepos.contains(fullName)) {
      snapshots.remove(fullName);
    }
    state = state.copyWith(monitoredRepos: next, repoSnapshots: snapshots);
    await _persistSet(_monitorsKey, next);
    await _persistRepoSnapshots(snapshots);
  }

  Future<void> addMonitorSkill(String fullName) async {
    final next = {...state.monitoredSkills, fullName};
    state = state.copyWith(monitoredSkills: next);
    await _persistSet(_skillsKey, next);
  }

  Future<void> removeMonitorSkill(String fullName) async {
    final next = {...state.monitoredSkills}..remove(fullName);
    state = state.copyWith(monitoredSkills: next);
    await _persistSet(_skillsKey, next);
  }

  Future<void> toggleMonitorSkill(String fullName) async {
    final next = {...state.monitoredSkills};
    if (!next.add(fullName)) {
      next.remove(fullName);
    }
    state = state.copyWith(monitoredSkills: next);
    await _persistSet(_skillsKey, next);
  }

  Future<void> toggleDeveloper(ContributorEntity developer) async {
    final login = developer.login;
    final next = {...state.followedDevelopers};
    final snapshots = {...state.developerSnapshots};
    if (next.add(login)) {
      snapshots[login] = SavedDeveloperSnapshot.fromEntity(developer, DateTime.now());
    } else {
      next.remove(login);
      snapshots.remove(login);
    }
    state = state.copyWith(followedDevelopers: next, developerSnapshots: snapshots);
    await _persistSet(_developersKey, next);
    await _persistDeveloperSnapshots(snapshots);
  }

  Future<void> setMonitorRule(int index, bool enabled) async {
    if (index < 0 || index >= state.monitorRules.length) {
      return;
    }
    final next = [...state.monitorRules]..[index] = enabled;
    state = state.copyWith(monitorRules: next);
    await ref.read(sharedPreferencesProvider).setStringList(_rulesKey, [for (final value in next) value ? '1' : '0']);
  }

  Future<void> setCachedUser({String? name, String? avatarUrl}) async {
    state = state.copyWith(cachedUserName: name, cachedAvatarUrl: avatarUrl);
    final prefs = ref.read(sharedPreferencesProvider);
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
    if (avatarUrl != null) {
      await prefs.setString(_userAvatarKey, avatarUrl);
    }
  }

  Future<void> clearCachedUser() async {
    state = state.copyWith(clearCachedUser: true);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userAvatarKey);
  }

  Set<String> _readSet(List<String>? raw, List<String> fallback) {
    final values = raw ?? fallback;
    return values.where((item) => item.trim().isNotEmpty).toSet();
  }

  List<bool> _readRules(List<String>? raw) {
    if (raw == null || raw.length != monitorRuleCount) {
      return const [true, true, false, true];
    }
    return [for (final value in raw) value == '1' || value == 'true'];
  }

  Future<void> _persistSet(String key, Set<String> values) {
    final sorted = values.toList()..sort();
    return ref.read(sharedPreferencesProvider).setStringList(key, sorted);
  }

  Future<void> _persistRepoSnapshots(Map<String, SavedRepoSnapshot> snapshots) {
    return ref.read(sharedPreferencesProvider).setString(_repoSnapshotsKey, encodeRepoSnapshots(snapshots));
  }

  Future<void> _persistDeveloperSnapshots(Map<String, SavedDeveloperSnapshot> snapshots) {
    return ref.read(sharedPreferencesProvider).setString(_developerSnapshotsKey, encodeDeveloperSnapshots(snapshots));
  }
}

final localContentControllerProvider = NotifierProvider<LocalContentController, LocalContentState>(LocalContentController.new);
