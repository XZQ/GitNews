/*
*客户端可展示的认证能力。
*/
class AuthCapabilities {
  const AuthCapabilities({required this.isConfigured, this.phone = false, this.email = false, this.github = false, this.google = false});

  const AuthCapabilities.unconfigured() : this(isConfigured: false);

  // 认证服务基础配置是否可用。
  final bool isConfigured;

  // 手机验证码是否已由发布方启用。
  final bool phone;

  // 邮箱验证码是否已由发布方启用。
  final bool email;

  // GitHub OAuth 是否已由发布方启用。
  final bool github;

  // Google OAuth 是否已由发布方启用。
  final bool google;

  bool get hasAnyMethod => phone || email || github || google;
}

/*
*应用账号身份。
*
*只包含 UI 和本地数据作用域需要的字段，不暴露 access token 或 refresh token。
*/
class AppIdentity {
  const AppIdentity({required this.userId, required this.displayName, this.phone, this.email, this.avatarUrl, this.providers = const <String>{}});

  // 服务端签发的稳定用户 ID。
  final String userId;

  // 用户可见名称。
  final String displayName;

  // 已验证手机号；仅在需要时以脱敏形式展示。
  final String? phone;

  // 已验证邮箱；仅在需要时以脱敏形式展示。
  final String? email;

  // 头像 URL。
  final String? avatarUrl;

  // 已绑定的身份提供商名称。
  final Set<String> providers;

  @override
  bool operator ==(Object other) {
    return other is AppIdentity &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.phone == phone &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.providers.length == providers.length &&
        other.providers.containsAll(providers);
  }

  @override
  int get hashCode => Object.hash(userId, displayName, phone, email, avatarUrl, Object.hashAllUnordered(providers));
}

/*
*应用支持的第三方登录提供商。
*/
enum AppAuthProvider {
  // GitHub OAuth。
  github,

  // Google OAuth。
  google,
}

/*
*可安全映射为用户提示的认证失败类型。
*/
enum AppAuthFailureKind {
  // 认证未配置。
  unconfigured,

  // 当前登录方式未启用。
  methodDisabled,

  // 手机号、邮箱或验证码格式错误。
  invalidInput,

  // 验证码错误。
  invalidOtp,

  // 验证码已过期。
  otpExpired,

  // 请求过于频繁。
  rateLimited,

  // 网络不可用或连接中断。
  network,

  // 认证服务当前不可用。
  serviceUnavailable,

  // 第三方登录页未能打开或被用户取消。
  providerUnavailable,

  // 未分类错误。
  unknown,
}

/*
*跨 SDK 边界的认证失败。
*
*只携带稳定错误类型，不把 provider 原始响应、手机号、邮箱或 token 传到 UI。
*/
class AppAuthFailure implements Exception {
  const AppAuthFailure(this.kind);

  // 稳定失败类型。
  final AppAuthFailureKind kind;

  @override
  String toString() => 'AppAuthFailure(${kind.name})';
}
