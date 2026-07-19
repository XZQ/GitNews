import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_config.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'auth_secure_storage.dart';
import 'email_address.dart';

/* 创建不会阻断应用启动的认证仓库。 */
Future<AuthRepository> initializeAuthRepository(FlutterSecureStorage secureStorage) async {
  if (!AuthConfig.isConfigured) {
    return const UnconfiguredAuthRepository();
  }
  const capabilities = AuthCapabilities(isConfigured: true);
  final uri = Uri.tryParse(AuthConfig.supabaseUrl.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return const UnavailableAuthRepository(capabilities);
  }
  try {
    final instance = await Supabase.initialize(
      url: uri.toString(),
      publishableKey: AuthConfig.supabasePublishableKey.trim(),
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce, localStorage: SecureAuthLocalStorage(secureStorage), pkceAsyncStorage: SecureAuthPkceStorage(secureStorage)),
    );
    return SupabaseAuthRepository(instance.client, capabilities: capabilities);
  } catch (_) {
    return const UnavailableAuthRepository(capabilities);
  }
}

/*
*Supabase Auth 适配器。
*
*SDK User 会在边界处转换为应用领域身份，provider 原始错误转换为稳定失败类型。
*/
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client, {required this.capabilities});

  // Supabase 客户端。
  final SupabaseClient _client;

  @override
  final AuthCapabilities capabilities;

  @override
  AppIdentity? get currentIdentity => _identityFromUser(_client.auth.currentUser);

  @override
  Stream<AppIdentity?> get identityChanges => _client.auth.onAuthStateChange.map((event) => _identityFromUser(event.session?.user)).distinct();

  @override
  Future<void> sendEmailOtp(String email) async {
    await _guard(() => _client.auth.signInWithOtp(email: email));
  }

  @override
  Future<AppIdentity> verifyEmailOtp({required String email, required String token}) async {
    final response = await _guard(() => _client.auth.verifyOTP(email: email, token: token, type: OtpType.email));
    return _requireIdentity(response.user ?? response.session?.user);
  }

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) async {
    final supabaseProvider = switch (provider) {
      AppAuthProvider.github => OAuthProvider.github,
      AppAuthProvider.google => OAuthProvider.google,
    };
    final opened = await _guard(() => _client.auth.signInWithOAuth(supabaseProvider, redirectTo: AuthConfig.redirectUrl, authScreenLaunchMode: LaunchMode.externalApplication));
    if (!opened) {
      throw const AppAuthFailure(AppAuthFailureKind.providerUnavailable);
    }
  }

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut(scope: SignOutScope.local));

  /* 确保验证码校验后确实产生了可用用户。 */
  AppIdentity _requireIdentity(User? user) {
    final identity = _identityFromUser(user);
    if (identity == null) {
      throw const AppAuthFailure(AppAuthFailureKind.unknown);
    }
    return identity;
  }

  /* 把 Supabase 异常转换为不包含敏感上下文的领域错误。 */
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw _mapFailure(error);
    } catch (_) {
      throw const AppAuthFailure(AppAuthFailureKind.network);
    }
  }
}

/* 把 provider 用户转换为稳定应用身份。 */
AppIdentity? _identityFromUser(User? user) {
  if (user == null || user.id.trim().isEmpty) {
    return null;
  }
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final displayName = _firstString(metadata, const ['display_name', 'full_name', 'name', 'user_name']) ?? maskEmailAddress(user.email).trim().takeIfNotEmpty() ?? 'AI 用户';
  return AppIdentity(
    userId: user.id,
    displayName: displayName,
    email: user.email,
    avatarUrl: _firstString(metadata, const ['avatar_url', 'picture']),
    providers: {for (final identity in user.identities ?? const <UserIdentity>[]) identity.provider},
  );
}

/* 按优先级读取非空字符串元数据。 */
String? _firstString(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

/* 把 Supabase 错误码归一化为稳定失败类型。 */
AppAuthFailure _mapFailure(AuthException error) {
  final code = '${error.code ?? ''} ${error.message}'.toLowerCase();
  final status = int.tryParse(error.statusCode ?? '');
  if (code.contains('otp_expired') || code.contains('expired')) {
    return const AppAuthFailure(AppAuthFailureKind.otpExpired);
  }
  if (code.contains('otp') && (code.contains('invalid') || code.contains('verify'))) {
    return const AppAuthFailure(AppAuthFailureKind.invalidOtp);
  }
  if (status == 429 || code.contains('rate') || code.contains('too many')) {
    return const AppAuthFailure(AppAuthFailureKind.rateLimited);
  }
  if (status == null || status >= 500) {
    return const AppAuthFailure(AppAuthFailureKind.network);
  }
  if (status == 400 || status == 422) {
    return const AppAuthFailure(AppAuthFailureKind.invalidInput);
  }
  return const AppAuthFailure(AppAuthFailureKind.unknown);
}

extension on String {
  /* 返回非空字符串，否则返回 null。 */
  String? takeIfNotEmpty() => isEmpty ? null : this;
}
