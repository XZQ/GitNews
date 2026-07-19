import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_models.dart';
import 'auth_repository.dart';
import 'email_address.dart';

/*
*当前认证操作。
*/
enum AuthOperation {
  // 没有进行中的认证动作。
  idle,

  // 正在发送验证码。
  sendingCode,

  // 验证码已发送，等待用户输入。
  codeSent,

  // 正在校验验证码。
  verifyingCode,

  // 正在打开第三方授权页。
  openingProvider,

  // 正在退出当前设备会话。
  signingOut,
}

/*
*全局应用账号会话状态。
*/
class AuthSessionState {
  const AuthSessionState({required this.capabilities, this.identity, this.operation = AuthOperation.idle, this.pendingEmail, this.resendAvailableAt, this.failure});

  // 当前构建可用的认证方式。
  final AuthCapabilities capabilities;

  // 当前应用账号；为空表示匿名。
  final AppIdentity? identity;

  // 当前认证操作。
  final AuthOperation operation;

  // 内存中的待验证邮箱；不持久化、不记录日志。
  final String? pendingEmail;

  // 允许再次发送验证码的时间。
  final DateTime? resendAvailableAt;

  // 最近一次稳定失败类型。
  final AppAuthFailureKind? failure;

  bool get isAuthenticated => identity != null;

  bool get isBusy => operation == AuthOperation.sendingCode || operation == AuthOperation.verifyingCode || operation == AuthOperation.openingProvider || operation == AuthOperation.signingOut;

  String get maskedPendingEmail => maskEmailAddress(pendingEmail);
}

/*
*应用账号会话控制器。
*
*负责邮箱格式、验证码状态、provider 启动和退出；凭据生命周期由仓库处理。
*/
class AuthSessionController extends Notifier<AuthSessionState> {
  late AuthRepository _repository;
  StreamSubscription<AppIdentity?>? _subscription;
  bool _disposed = false;

  @override
  AuthSessionState build() {
    _repository = ref.watch(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = _repository.identityChanges.listen(_handleIdentityChange);
    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
    });
    return AuthSessionState(capabilities: _repository.capabilities, identity: _repository.currentIdentity);
  }

  /* 发送邮箱验证码。 */
  Future<void> sendEmailCode(String input) async {
    final email = input.trim().toLowerCase();
    if (!_looksLikeEmail(email)) {
      state = _next(operation: AuthOperation.idle, failure: AppAuthFailureKind.invalidInput, clearFailure: false);
      return;
    }
    if (!_canSendAgain()) {
      state = _next(operation: AuthOperation.codeSent, failure: AppAuthFailureKind.rateLimited, clearFailure: false);
      return;
    }
    state = _next(operation: AuthOperation.sendingCode, clearFailure: true);
    try {
      await _repository.sendEmailOtp(email);
      state = AuthSessionState(
        capabilities: state.capabilities,
        identity: state.identity,
        operation: AuthOperation.codeSent,
        pendingEmail: email,
        resendAvailableAt: DateTime.now().add(const Duration(seconds: 60)),
      );
    } on AppAuthFailure catch (failure) {
      state = _next(operation: AuthOperation.idle, failure: failure.kind, clearFailure: false);
    }
  }

  /* 校验当前邮箱验证码。 */
  Future<void> verifyCode(String input) async {
    final token = input.trim();
    final email = state.pendingEmail;
    if (!RegExp(r'^\d{6}$').hasMatch(token) || email == null) {
      state = _next(operation: AuthOperation.codeSent, failure: AppAuthFailureKind.invalidInput, clearFailure: false);
      return;
    }
    state = _next(operation: AuthOperation.verifyingCode, clearFailure: true);
    try {
      final identity = await _repository.verifyEmailOtp(email: email, token: token);
      state = AuthSessionState(capabilities: state.capabilities, identity: identity);
    } on AppAuthFailure catch (failure) {
      state = _next(operation: AuthOperation.codeSent, failure: failure.kind, clearFailure: false);
    }
  }

  /* 使用已启用的第三方 provider 登录。 */
  Future<void> signInWithProvider(AppAuthProvider provider) async {
    state = _next(operation: AuthOperation.openingProvider, clearFailure: true);
    try {
      await _repository.signInWithProvider(provider);
      state = _next(operation: AuthOperation.idle, clearFailure: true);
    } on AppAuthFailure catch (failure) {
      state = _next(operation: AuthOperation.idle, failure: failure.kind, clearFailure: false);
    }
  }

  /* 退出当前设备的应用账号，不处理 GitHub API Token。 */
  Future<void> signOut() async {
    state = _next(operation: AuthOperation.signingOut, clearFailure: true);
    try {
      await _repository.signOut();
      state = AuthSessionState(capabilities: state.capabilities);
    } on AppAuthFailure catch (failure) {
      state = _next(operation: AuthOperation.idle, failure: failure.kind, clearFailure: false);
    }
  }

  /* 返回验证码方式选择页。 */
  void resetChallenge() {
    state = AuthSessionState(capabilities: state.capabilities, identity: state.identity);
  }

  /* 清除已展示的错误。 */
  void clearFailure() {
    state = _next(operation: state.operation, clearFailure: true);
  }

  /* 同步 SDK 发出的登录、刷新和退出事件。 */
  void _handleIdentityChange(AppIdentity? identity) {
    if (_disposed) {
      return;
    }
    state = AuthSessionState(capabilities: state.capabilities, identity: identity);
  }

  /* 本机倒计时之外不允许重复发送。 */
  bool _canSendAgain() {
    final availableAt = state.resendAvailableAt;
    return availableAt == null || !DateTime.now().isBefore(availableAt);
  }

  /* 轻量校验邮箱格式；最终合法性仍由认证服务判断。 */
  bool _looksLikeEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  /* 从当前状态派生下一状态，避免把验证码目标写入持久化。 */
  AuthSessionState _next({required AuthOperation operation, AppAuthFailureKind? failure, required bool clearFailure}) {
    return AuthSessionState(
      capabilities: state.capabilities,
      identity: state.identity,
      operation: operation,
      pendingEmail: state.pendingEmail,
      resendAvailableAt: state.resendAvailableAt,
      failure: clearFailure ? null : failure ?? state.failure,
    );
  }
}

final authSessionControllerProvider = NotifierProvider<AuthSessionController, AuthSessionState>(AuthSessionController.new);
