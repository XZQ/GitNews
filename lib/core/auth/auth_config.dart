/*
*应用账号认证构建配置。
*
*所有值只从 dart-define 读取。publishable key 可以随客户端分发，
*service role key 与 OAuth client secret 不得进入客户端。
*/
class AuthConfig {
  AuthConfig._();

  // Supabase 项目地址。
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  // Supabase 客户端 publishable key，不是 service role key。
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // OAuth 完成后返回应用的 URI。
  static const String redirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL', defaultValue: 'github-news://auth-callback/');

  /* 返回认证服务的基础配置是否完整。 */
  static bool get isConfigured => supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;
}
