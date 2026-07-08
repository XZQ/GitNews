import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo_data.dart';
import '../di/providers.dart';
import '../i18n/app_localizations.dart';

const int monitorRuleCount = 4;

List<String> monitorRuleLabels(AppLocalizations l10n) => [
  l10n.tr('monitor.rule.star_growth'),
  l10n.tr('monitor.rule.daily_growth'),
  l10n.tr('monitor.rule.fork_growth'),
  l10n.tr('monitor.rule.discuss_heat'),
];

class LocalContentState {
  const LocalContentState({
    required this.bookmarkedRepos,
    required this.monitoredRepos,
    required this.monitoredSkills,
    required this.followedDevelopers,
    required this.monitorRules,
    this.cachedUserName,
    this.cachedAvatarUrl,
  });

  final Set<String> bookmarkedRepos;
  final Set<String> monitoredRepos;
  final Set<String> monitoredSkills;
  final Set<String> followedDevelopers;
  final List<bool> monitorRules;
  final String? cachedUserName;
  final String? cachedAvatarUrl;

  int get enabledRuleCount => monitorRules.where((enabled) => enabled).length;

  bool isBookmarked(String fullName) => bookmarkedRepos.contains(fullName);

  bool isMonitored(String fullName) => monitoredRepos.contains(fullName);

  bool isMonitoredSkill(String fullName) => monitoredSkills.contains(fullName);

  bool isFollowingDeveloper(String login) =>
      followedDevelopers.contains(login);

  LocalContentState copyWith({
    Set<String>? bookmarkedRepos,
    Set<String>? monitoredRepos,
    Set<String>? monitoredSkills,
    Set<String>? followedDevelopers,
    List<bool>? monitorRules,
    String? cachedUserName,
    String? cachedAvatarUrl,
    bool clearCachedUser = false,
  }) {
    return LocalContentState(
      bookmarkedRepos: bookmarkedRepos ?? this.bookmarkedRepos,
      monitoredRepos: monitoredRepos ?? this.monitoredRepos,
      monitoredSkills: monitoredSkills ?? this.monitoredSkills,
      followedDevelopers: followedDevelopers ?? this.followedDevelopers,
      monitorRules: monitorRules ?? this.monitorRules,
      cachedUserName: clearCachedUser
          ? null
          : (cachedUserName ?? this.cachedUserName),
      cachedAvatarUrl: clearCachedUser
          ? null
          : (cachedAvatarUrl ?? this.cachedAvatarUrl),
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

  @override
  LocalContentState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return LocalContentState(
      bookmarkedRepos: _readSet(
        prefs.getStringList(_bookmarksKey),
        _defaultBookmarkedRepos,
      ),
      monitoredRepos: _readSet(
        prefs.getStringList(_monitorsKey),
        _defaultMonitoredRepos,
      ),
      monitoredSkills: _readSet(
        prefs.getStringList(_skillsKey),
        const [],
      ),
      followedDevelopers: _readSet(
        prefs.getStringList(_developersKey),
        _defaultFollowedDevelopers,
      ),
      monitorRules: _readRules(prefs.getStringList(_rulesKey)),
      cachedUserName: prefs.getString(_userNameKey),
      cachedAvatarUrl: prefs.getString(_userAvatarKey),
    );
  }

  Future<void> toggleBookmark(String fullName) async {
    final next = {...state.bookmarkedRepos};
    if (!next.add(fullName)) next.remove(fullName);
    state = state.copyWith(bookmarkedRepos: next);
    await _persistSet(_bookmarksKey, next);
  }

  Future<void> removeBookmark(String fullName) async {
    final next = {...state.bookmarkedRepos}..remove(fullName);
    state = state.copyWith(bookmarkedRepos: next);
    await _persistSet(_bookmarksKey, next);
  }

  Future<void> addMonitor(String fullName) async {
    final next = {...state.monitoredRepos, fullName};
    state = state.copyWith(monitoredRepos: next);
    await _persistSet(_monitorsKey, next);
  }

  Future<void> removeMonitor(String fullName) async {
    final next = {...state.monitoredRepos}..remove(fullName);
    state = state.copyWith(monitoredRepos: next);
    await _persistSet(_monitorsKey, next);
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
    if (!next.add(fullName)) next.remove(fullName);
    state = state.copyWith(monitoredSkills: next);
    await _persistSet(_skillsKey, next);
  }

  Future<void> toggleDeveloper(String login) async {
    final next = {...state.followedDevelopers};
    if (!next.add(login)) next.remove(login);
    state = state.copyWith(followedDevelopers: next);
    await _persistSet(_developersKey, next);
  }

  Future<void> setMonitorRule(int index, bool enabled) async {
    if (index < 0 || index >= state.monitorRules.length) return;
    final next = [...state.monitorRules]..[index] = enabled;
    state = state.copyWith(monitorRules: next);
    await ref.read(sharedPreferencesProvider).setStringList(
      _rulesKey,
      [for (final value in next) value ? '1' : '0'],
    );
  }

  Future<void> setCachedUser({String? name, String? avatarUrl}) async {
    state = state.copyWith(cachedUserName: name, cachedAvatarUrl: avatarUrl);
    final prefs = ref.read(sharedPreferencesProvider);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (avatarUrl != null) await prefs.setString(_userAvatarKey, avatarUrl);
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
}

final localContentControllerProvider =
    NotifierProvider<LocalContentController, LocalContentState>(
  LocalContentController.new,
);

final List<String> _defaultBookmarkedRepos = [
  for (final repo in DemoData.trending.take(4)) repo.fullName,
];

final List<String> _defaultMonitoredRepos = [
  for (final repo in DemoData.trending.take(4)) repo.fullName,
  for (final repo in DemoData.recent) repo.fullName,
];

final List<String> _defaultFollowedDevelopers = {
  for (final contributor in DemoData.contributors) contributor.login,
}.toList();
