/*
*AI 代理只允许 HTTPS 或本机调试，不携带共享凭据。
*/
class AiEnrichmentApiSupport {
  const AiEnrichmentApiSupport._();

  /* 用户会话仅进入 Authorization。 */
  static Map<String, String> headers(String accessToken) => {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'};

  /* 只接受服务 origin，拒绝 URL 内凭据、路径和查询参数。 */
  static bool isAllowedServiceUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment || (uri.path.isNotEmpty && uri.path != '/')) {
      return false;
    }
    return uri.scheme == 'https' || (uri.scheme == 'http' && const {'localhost', '127.0.0.1', '::1'}.contains(uri.host));
  }
}
