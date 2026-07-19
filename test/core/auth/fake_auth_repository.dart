import 'dart:async';

import 'package:github_news/core/auth/auth_models.dart';
import 'package:github_news/core/auth/auth_repository.dart';

/*
*认证控制器与 Widget 测试共用的内存仓库。
*/
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({required this.capabilities, this.identity, this.acceptedCode = '123456'});

  @override
  final AuthCapabilities capabilities;

  // 当前身份。
  AppIdentity? identity;

  // 测试接受的验证码。
  final String acceptedCode;

  // 最近发送的邮箱。
  String? sentEmail;

  // 最近打开的 provider。
  AppAuthProvider? openedProvider;

  // 退出次数。
  int signOutCalls = 0;

  final StreamController<AppIdentity?> _controller = StreamController<AppIdentity?>.broadcast();

  @override
  AppIdentity? get currentIdentity => identity;

  @override
  Stream<AppIdentity?> get identityChanges => _controller.stream;

  @override
  Future<void> sendEmailOtp(String email) async {
    sentEmail = email;
  }

  @override
  Future<AppIdentity> verifyEmailOtp({required String email, required String token}) async {
    if (token != acceptedCode) {
      throw const AppAuthFailure(AppAuthFailureKind.invalidOtp);
    }
    identity = AppIdentity(userId: 'user-email', displayName: 'Email User', email: email, providers: const {'email'});
    _controller.add(identity);
    return identity!;
  }

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) async {
    openedProvider = provider;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    identity = null;
    _controller.add(null);
  }

  /* 关闭测试流。 */
  Future<void> dispose() => _controller.close();
}
