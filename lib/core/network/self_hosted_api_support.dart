/*
*可选自托管服务的协议常量与请求头。
*baseUrl 与凭据由用户在设置页配置并绑定,此文件只负责协议细节。
*/
class SelfHostedApiSupport {
  const SelfHostedApiSupport._();

  /* 未绑定凭据时不发送 Authorization,避免产生看似有效的 Bearer 头。 */
  static Map<String, String> headers({required String? apiKey, required String workspaceId}) {
    return {if (apiKey != null && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey', 'X-Workspace-ID': workspaceId, 'Content-Type': 'application/json'};
  }
}
