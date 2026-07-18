/*
*应用账号认证构建配置。
*
*所有值只从 dart-define 读取。publishable key 可以随客户端分发，
*service role key、OAuth client secret 和短信供应商密钥不得进入客户端。
*/
class AuthConfig {
  AuthConfig._();

  // Supabase 项目地址。
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  // Supabase 客户端 publishable key，不是 service role key。
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // OAuth 完成后返回应用的 URI。
  static const String redirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL', defaultValue: 'github-news://auth-callback/');

  // 国内版默认手机区号。
  static const String defaultPhoneCountryCode = '+86';

  // 只有发布方确认真实短信供应商和风控已启用后才打开手机入口。
  static const bool phoneEnabled = bool.fromEnvironment('AUTH_PHONE_ENABLED');

  // 只有发布方确认 SMTP / 邮件模板后才打开邮箱入口。
  static const bool emailEnabled = bool.fromEnvironment('AUTH_EMAIL_ENABLED');

  // GitHub OAuth provider 开关。
  static const bool githubEnabled = bool.fromEnvironment('AUTH_GITHUB_ENABLED');

  // Google OAuth provider 开关。
  static const bool googleEnabled = bool.fromEnvironment('AUTH_GOOGLE_ENABLED');

  /* 返回认证服务的基础配置是否完整。 */
  static bool get isConfigured => supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;
}
