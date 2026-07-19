import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_models.dart';

/*
*应用账号认证仓库契约。
*
*页面和会话控制器只依赖此接口，不直接依赖 Supabase SDK。
*/
abstract interface class AuthRepository {
  AuthCapabilities get capabilities;

  AppIdentity? get currentIdentity;

  Stream<AppIdentity?> get identityChanges;

  Future<void> sendEmailOtp(String email);

  Future<AppIdentity> verifyEmailOtp({required String email, required String token});

  Future<void> signInWithProvider(AppAuthProvider provider);

  Future<void> signOut();
}

/*
*认证构建参数缺失时使用的仓库。
*
*匿名功能照常工作；所有远程认证动作返回明确的未配置失败。
*/
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  AuthCapabilities get capabilities => const AuthCapabilities.unconfigured();

  @override
  AppIdentity? get currentIdentity => null;

  @override
  Stream<AppIdentity?> get identityChanges => const Stream<AppIdentity?>.empty();

  @override
  Future<void> sendEmailOtp(String email) => _fail();

  @override
  Future<AppIdentity> verifyEmailOtp({required String email, required String token}) => _fail();

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) => _fail();

  @override
  Future<void> signOut() async {}

  /* 统一生成未配置失败。 */
  Future<T> _fail<T>() async => throw const AppAuthFailure(AppAuthFailureKind.unconfigured);
}

/*
*认证 SDK 初始化失败后的降级仓库。
*/
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository(this.capabilities);

  @override
  final AuthCapabilities capabilities;

  @override
  AppIdentity? get currentIdentity => null;

  @override
  Stream<AppIdentity?> get identityChanges => const Stream<AppIdentity?>.empty();

  @override
  Future<void> sendEmailOtp(String email) => _fail();

  @override
  Future<AppIdentity> verifyEmailOtp({required String email, required String token}) => _fail();

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) => _fail();

  @override
  Future<void> signOut() async {}

  /* 统一生成服务不可用失败。 */
  Future<T> _fail<T>() async => throw const AppAuthFailure(AppAuthFailureKind.serviceUnavailable);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnconfiguredAuthRepository());
