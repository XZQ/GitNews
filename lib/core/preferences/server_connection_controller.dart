import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

const String serverBaseUrlPreferenceKey = 'self_hosted_server_base_url';
const String serverWorkspacePreferenceKey = 'self_hosted_server_workspace';
const String serverMemberPreferenceKey = 'self_hosted_server_member';

class ServerConnectionState {
  const ServerConnectionState({
    this.baseUrl = 'http://127.0.0.1:8080',
    this.workspaceId = 'personal',
    this.memberId = 'desktop',
    this.apiKey,
  });

  final String baseUrl;
  final String workspaceId;
  final String memberId;
  final String? apiKey;

  bool get configured => apiKey != null && apiKey!.isNotEmpty;

  String get maskedKey {
    final value = apiKey;
    if (value == null || value.isEmpty) {
      return '';
    }
    return value.length <= 8 ? '••••••••' : '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';
  }
}

class ServerConnectionController extends Notifier<ServerConnectionState> {
  static const _secureKey = 'self_hosted_server_api_key';

  @override
  ServerConnectionState build() {
    _load();
    final preferences = ref.read(sharedPreferencesProvider);
    return ServerConnectionState(
      baseUrl: preferences.getString(serverBaseUrlPreferenceKey) ?? 'http://127.0.0.1:8080',
      workspaceId: preferences.getString(serverWorkspacePreferenceKey) ?? 'personal',
      memberId: preferences.getString(serverMemberPreferenceKey) ?? 'desktop',
    );
  }

  Future<void> _load() async {
    try {
      final apiKey = await ref.read(secureStorageProvider).read(key: _secureKey);
      state = ServerConnectionState(
        baseUrl: state.baseUrl,
        workspaceId: state.workspaceId,
        memberId: state.memberId,
        apiKey: apiKey,
      );
    } catch (_) {
      // 安全存储在无插件的测试/受限环境不可用时保留非敏感配置。
    }
  }

  Future<void> save({
    required String baseUrl,
    required String workspaceId,
    required String memberId,
    required String apiKey,
  }) async {
    final normalizedUrl = normalizeServerBaseUrl(baseUrl);
    final workspace = _identifier(workspaceId, 'workspace');
    final member = _identifier(memberId, 'member');
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const FormatException('API key is required');
    }
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(serverBaseUrlPreferenceKey, normalizedUrl);
    await preferences.setString(serverWorkspacePreferenceKey, workspace);
    await preferences.setString(serverMemberPreferenceKey, member);
    await ref.read(secureStorageProvider).write(key: _secureKey, value: key);
    state = ServerConnectionState(
      baseUrl: normalizedUrl,
      workspaceId: workspace,
      memberId: member,
      apiKey: key,
    );
  }
}

String normalizeServerBaseUrl(String raw) {
  final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException('Server URL must be absolute HTTP(S)');
  }
  return value;
}

String _identifier(String raw, String field) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 120) {
    throw FormatException('Invalid $field identifier');
  }
  return value;
}

final serverConnectionControllerProvider = NotifierProvider<ServerConnectionController, ServerConnectionState>(
  ServerConnectionController.new,
);
