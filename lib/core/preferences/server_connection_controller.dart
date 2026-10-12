import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/providers.dart';
import '../utils/app_logger.dart';

const String serverBaseUrlPreferenceKey = 'self_hosted_server_base_url';
const String serverWorkspacePreferenceKey = 'self_hosted_server_workspace';
const String serverMemberPreferenceKey = 'self_hosted_server_member';

const String kDefaultServerBaseUrl = 'http://127.0.0.1:8080';
const String kDefaultWorkspaceId = 'personal';
const String kDefaultMemberId = 'desktop';

/*
*服务地址、工作区和与该地址绑定的本机凭据。
*/
class ServerConnectionState {
  const ServerConnectionState({this.baseUrl = kDefaultServerBaseUrl, this.workspaceId = kDefaultWorkspaceId, this.memberId = kDefaultMemberId, this.apiKey});

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

/*
*串行维护自托管连接；安全存储中的 Key 只可用于保存时对应的地址。
*/
class ServerConnectionController extends Notifier<ServerConnectionState> {
  static const _secureKey = 'self_hosted_server_connection_v2';
  static const _legacySecureKey = 'self_hosted_server_api_key';

  // 初始化、保存和配置导入共用队列，避免异步旧结果覆盖新连接。
  Future<void> _pending = Future<void>.value();

  // 在同步 build 阶段捕获存储依赖。
  late FlutterSecureStorage _secure;
  late SharedPreferences _preferences;

  // 最近成功解码的安全凭据；配置导入结束后无需再次访问插件。
  ({String baseUrl, String apiKey})? _credential;

  @override
  ServerConnectionState build() {
    _secure = ref.read(secureStorageProvider);
    _preferences = ref.read(sharedPreferencesProvider);
    final initial = _readPreferences();
    unawaited(
      _enqueue(() => _load(initial)).catchError((Object error) {
        AppLogger.warn('serverConnectionLoad', meta: {'error': error.runtimeType.toString()});
      }),
    );
    return initial;
  }

  /* 等待当前排入队列的连接操作。 */
  Future<void> get ready => _pending;

  /* 同步读取非敏感设置；凭据须经过安全存储的地址匹配。 */
  ServerConnectionState _readPreferences() {
    return ServerConnectionState(
      baseUrl: _preferences.getString(serverBaseUrlPreferenceKey) ?? kDefaultServerBaseUrl,
      workspaceId: _preferences.getString(serverWorkspacePreferenceKey) ?? kDefaultWorkspaceId,
      memberId: _preferences.getString(serverMemberPreferenceKey) ?? kDefaultMemberId,
    );
  }

  /* 升级旧凭据时先绑定原地址，随后才允许配置导入改变地址。 */
  Future<void> _load(ServerConnectionState connection) async {
    final baseUrl = normalizeServerBaseUrl(connection.baseUrl);
    var document = await _secure.read(key: _secureKey);
    if (document == null) {
      final legacy = await _secure.read(key: _legacySecureKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        document = _credentialDocument(baseUrl, legacy.trim());
        await _secure.write(key: _secureKey, value: document);
        await _secure.delete(key: _legacySecureKey);
      }
    } else {
      // 已绑定的 v2 凭据是唯一事实源；不再留下可以被重新迁移的旧 Key。
      await _secure.delete(key: _legacySecureKey);
    }
    _credential = document == null ? null : _decodeCredential(document);
    _publish(ServerConnectionState(baseUrl: baseUrl, workspaceId: connection.workspaceId, memberId: connection.memberId, apiKey: _credential?.baseUrl == baseUrl ? _credential?.apiKey : null));
  }

  /* 完成绑定凭据与普通设置的持久化，失败时恢复原连接并保留错误。 */
  Future<void> save({required String baseUrl, required String workspaceId, required String memberId, required String apiKey}) {
    final normalizedUrl = normalizeServerBaseUrl(baseUrl);
    final workspace = _identifier(workspaceId, 'workspace');
    final member = _identifier(memberId, 'member');
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const FormatException('API key is required');
    }
    return _enqueue(() async {
      final oldDocument = await _secure.read(key: _secureKey);
      final oldValues = <String, String?>{
        for (final name in [serverBaseUrlPreferenceKey, serverWorkspacePreferenceKey, serverMemberPreferenceKey]) name: _preferences.getString(name),
      };
      // 先绑定新 Key；即使进程在普通偏好写入途中终止，也不能把旧 Key 发到新地址。
      await _secure.write(key: _secureKey, value: _credentialDocument(normalizedUrl, key));
      try {
        await _writePreference(serverBaseUrlPreferenceKey, normalizedUrl);
        await _writePreference(serverWorkspacePreferenceKey, workspace);
        await _writePreference(serverMemberPreferenceKey, member);
        await _secure.delete(key: _legacySecureKey);
      } catch (_) {
        await _rollback(oldValues, oldDocument);
        rethrow;
      }
      _credential = (baseUrl: normalizedUrl, apiKey: key);
      _publish(ServerConnectionState(baseUrl: normalizedUrl, workspaceId: workspace, memberId: member, apiKey: key));
    });
  }

  /* 配置导入与保存串行；初始化失败时禁止把无作用域旧 Key 绑定到导入地址。 */
  Future<T> importPreferences<T>(Future<T> Function() action) {
    final operation = _pending.then((_) async {
      // 初始化失败必须重试原地址迁移，完成前不修改服务器偏好。
      await _load(_readPreferences());
      final result = await action();
      final connection = _readPreferences();
      final baseUrl = normalizeServerBaseUrl(connection.baseUrl);
      _publish(ServerConnectionState(baseUrl: baseUrl, workspaceId: connection.workspaceId, memberId: connection.memberId, apiKey: _credential?.baseUrl == baseUrl ? _credential?.apiKey : null));
      return result;
    });
    _pending = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /* 检查 SharedPreferences 返回值，不把失败当作保存成功。 */
  Future<void> _writePreference(String key, String value) async {
    if (!await _preferences.setString(key, value)) {
      throw StateError('Failed to persist server connection preference');
    }
  }

  /* 最佳努力恢复，凭据仍有地址绑定，部分回滚失败也不会转发到另一服务器。 */
  Future<void> _rollback(Map<String, String?> oldValues, String? oldDocument) async {
    for (final entry in oldValues.entries) {
      try {
        final value = entry.value;
        if (value == null) {
          await _preferences.remove(entry.key);
        } else {
          await _preferences.setString(entry.key, value);
        }
      } catch (_) {
        // 继续恢复其他项。
      }
    }
    try {
      if (oldDocument == null) {
        await _secure.delete(key: _secureKey);
      } else {
        await _secure.write(key: _secureKey, value: oldDocument);
      }
    } catch (_) {
      // 保留原始写入错误；仍存在的 Key 只能匹配自己的服务器。
    }
  }

  /* 操作失败不阻断后续重试，每个调用仍收到自己的失败。 */
  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /* 控制器销毁后不再发布异步加载结果。 */
  void _publish(ServerConnectionState next) {
    if (ref.mounted) {
      state = next;
    }
  }
}

/* 规范化服务器地址；保留挂载路径，拒绝凭据、查询和片段。 */
String normalizeServerBaseUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException('Server URL must be absolute HTTP(S)');
  }
  final defaultPort = uri.scheme == 'https' ? 443 : 80;
  return Uri(scheme: uri.scheme, host: uri.host.toLowerCase(), port: uri.port == defaultPort ? null : uri.port, path: uri.normalizePath().path.replaceFirst(RegExp(r'/+$'), '')).toString();
}

/* 校验工作区和成员标识。 */
String _identifier(String raw, String field) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 120) {
    throw FormatException('Invalid $field identifier');
  }
  return value;
}

/* 将服务器作用域和 Key 一并保存在安全存储。 */
String _credentialDocument(String baseUrl, String apiKey) => jsonEncode({'base_url': baseUrl, 'api_key': apiKey});

/* 解码凭据时严格校验地址；损坏记录不能产生可发送的 Key。 */
({String baseUrl, String apiKey})? _decodeCredential(String document) {
  try {
    final decoded = jsonDecode(document);
    if (decoded is! Map<String, dynamic> || decoded['base_url'] is! String || decoded['api_key'] is! String || (decoded['api_key'] as String).trim().isEmpty) {
      return null;
    }
    return (baseUrl: normalizeServerBaseUrl(decoded['base_url'] as String), apiKey: (decoded['api_key'] as String).trim());
  } catch (_) {
    return null;
  }
}

final serverConnectionControllerProvider = NotifierProvider<ServerConnectionController, ServerConnectionState>(ServerConnectionController.new);
