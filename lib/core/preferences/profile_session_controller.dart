import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

class ProfileSessionState {
  const ProfileSessionState({this.displayName});

  final String? displayName;

  bool get isSignedIn => displayName != null && displayName!.trim().isNotEmpty;

  String get effectiveName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return 'dev_explorer';
    return name;
  }

  String get statusText {
    return isSignedIn ? '本地账号 · 已登录' : '匿名浏览 · 登录后可同步数据';
  }
}

class ProfileSessionController extends Notifier<ProfileSessionState> {
  static const _kDisplayNameKey = 'profile_display_name';

  @override
  ProfileSessionState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ProfileSessionState(
      displayName: prefs.getString(_kDisplayNameKey),
    );
  }

  Future<void> signInLocal(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) return signOut();
    state = ProfileSessionState(displayName: name);
    await ref.read(sharedPreferencesProvider).setString(_kDisplayNameKey, name);
  }

  Future<void> signOut() async {
    state = const ProfileSessionState();
    await ref.read(sharedPreferencesProvider).remove(_kDisplayNameKey);
  }
}

final profileSessionControllerProvider =
    NotifierProvider<ProfileSessionController, ProfileSessionState>(
  ProfileSessionController.new,
);
