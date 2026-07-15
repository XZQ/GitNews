import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_endpoints_config.dart';
import '../errors/app_exception.dart';
import '../network/dio_client.dart';
import '../preferences/github_token_controller.dart';
import '../preferences/profile_session_controller.dart';
import '../shared/local_content_controller.dart';
import 'github_api_support.dart';

/*
 *GitHub Device Flow 登录状态机。
 */
enum DeviceFlowStatus {
  idle,
  awaiting,
  polling,
  success,
  error,
  expired,
  denied,
}

class DeviceFlowState {
  const DeviceFlowState({
    this.status = DeviceFlowStatus.idle,
    this.userCode,
    this.verificationUri,
    this.verificationUriComplete,
    this.interval = 5,
    this.expiresIn = 900,
    this.error,
  });

  final DeviceFlowStatus status;
  final String? userCode;
  final String? verificationUri;
  final String? verificationUriComplete;
  final int interval;
  final int expiresIn;
  final String? error;

  DeviceFlowState copyWith({
    DeviceFlowStatus? status,
    String? userCode,
    String? verificationUri,
    String? verificationUriComplete,
    int? interval,
    int? expiresIn,
    String? error,
  }) =>
      DeviceFlowState(
        status: status ?? this.status,
        userCode: userCode ?? this.userCode,
        verificationUri: verificationUri ?? this.verificationUri,
        verificationUriComplete: verificationUriComplete ?? this.verificationUriComplete,
        interval: interval ?? this.interval,
        expiresIn: expiresIn ?? this.expiresIn,
        error: error ?? this.error,
      );
}

/*
 *GitHub Device Flow OAuth 控制器。
 *
 *桌面端无回调 URL,采用 Device Flow:
 *1. [start] 向 `/login/device/code` 申请 `device_code` + `user_code`;
 *2. 自动打开浏览器到授权页,用户粘贴 `user_code` 完成授权;
 *3. 后台轮询 `/login/oauth/access_token`,拿到 `access_token` 后写入
 *   [githubTokenControllerProvider](安全存储)并拉取真实用户信息回填
 *   [localContentControllerProvider]。
 */
class GithubDeviceFlowController extends Notifier<DeviceFlowState> {
  static const String _scope = 'read:user';

  Timer? _timer;
  String? _deviceCode;

  @override
  DeviceFlowState build() {
    ref.onDispose(() => _timer?.cancel());
    return const DeviceFlowState();
  }

  Dio get _dio => ref.read(githubDeviceFlowDioProvider);

  Future<void> start() async {
    if (!ApiEndpointsConfig.githubOAuthConfigured) {
      state = const DeviceFlowState(
        status: DeviceFlowStatus.error,
        error: 'not_configured',
      );
      return;
    }
    state = const DeviceFlowState(status: DeviceFlowStatus.awaiting);
    try {
      final resp = await _dio.post<Map<String, Object?>>(
        ApiEndpointsConfig.githubDeviceCodePath,
        data: {
          'client_id': ApiEndpointsConfig.githubOAuthClientId,
          'scope': _scope,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = resp.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      _deviceCode = GitHubJson.string(data['device_code']);
      state = DeviceFlowState(
        status: DeviceFlowStatus.awaiting,
        userCode: GitHubJson.string(data['user_code']),
        verificationUri: GitHubJson.string(data['verification_uri']),
        verificationUriComplete: GitHubJson.nullableString(
          data['verification_uri_complete'],
        ),
        interval: GitHubJson.intValue(data['interval']),
        expiresIn: GitHubJson.intValue(data['expires_in']),
      );
      final uri = state.verificationUriComplete ?? state.verificationUri;
      if (uri != null) {
        await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
      }
      _beginPolling();
    } on DioException catch (e) {
      state = DeviceFlowState(
        status: DeviceFlowStatus.error,
        error: e.message ?? 'network',
      );
    } on AppException catch (e) {
      state = DeviceFlowState(
        status: DeviceFlowStatus.error,
        error: e.kind.name,
      );
    } catch (e) {
      state = DeviceFlowState(
        status: DeviceFlowStatus.error,
        error: e.toString(),
      );
    }
  }

  void _beginPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: state.interval), (_) => _tick());
  }

  Future<void> _tick() async {
    final deviceCode = _deviceCode;
    if (deviceCode == null) {
      return;
    }
    try {
      final resp = await _dio.post<Map<String, Object?>>(
        ApiEndpointsConfig.githubDeviceTokenPath,
        data: {
          'client_id': ApiEndpointsConfig.githubOAuthClientId,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = resp.data;
      if (data == null) {
        return;
      }
      if (data['error'] != null) {
        final err = GitHubJson.string(data['error']);
        if (err == 'authorization_pending') {
          return;
        }
        if (err == 'slow_down') {
          state = state.copyWith(interval: state.interval + 5);
          _beginPolling();
          return;
        }
        _timer?.cancel();
        state = DeviceFlowState(
          status: err == 'access_denied' ? DeviceFlowStatus.denied : DeviceFlowStatus.expired,
        );
        return;
      }
      final token = GitHubJson.string(data['access_token']);
      _timer?.cancel();
      await _complete(token);
    } on DioException {
      // 轮询期间网络抖动:保持等待,下次继续。
    }
  }

  Future<void> _complete(String token) async {
    await ref.read(githubTokenControllerProvider.notifier).setToken(token);
    try {
      final user = await DioClient.create().get<Map<String, Object?>>(
        ApiEndpointsConfig.githubUserPath,
        options: Options(headers: GitHubApiSupport.headers(token: token)),
      );
      final login = GitHubJson.nullableString(user.data?['login']);
      final avatar = GitHubJson.nullableString(user.data?['avatar_url']);
      if (login != null) {
        await ref.read(localContentControllerProvider.notifier).setCachedUser(name: login, avatarUrl: avatar);
        await ref.read(profileSessionControllerProvider.notifier).signInLocal(login);
      }
    } catch (_) {
      // 即便拉不到用户信息,Token 已写入,不影响后续 API 调用。
    }
    state = const DeviceFlowState(status: DeviceFlowStatus.success);
  }

  void cancel() {
    _timer?.cancel();
    _deviceCode = null;
    state = const DeviceFlowState();
  }
}

final githubDeviceFlowProvider = NotifierProvider<GithubDeviceFlowController, DeviceFlowState>(
  GithubDeviceFlowController.new,
);

final githubDeviceFlowDioProvider = Provider<Dio>(
  (ref) => DioClient.create(baseUrl: ApiEndpointsConfig.githubWebBaseUrl),
);
