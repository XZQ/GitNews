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

  /* 
  *Returns the i18n key for the current session status.
  */
  String get statusKey {
    return isSignedIn
        ? 'profile.session.signed_in'
        : 'profile.user.anonymous_status';
  }
}

class ProfileSessionController extends Notifier<ProfileSessionState> {
  static const _kDisplayNameKey = 'profile_display_name';

  @override
  ProfileSessionState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ProfileSessionState(displayName: prefs.getString(_kDisplayNameKey));
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
