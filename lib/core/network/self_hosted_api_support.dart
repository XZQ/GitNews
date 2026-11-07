/*
*可选自托管服务的协议常量与请求头。
*baseUrl 与凭据由用户在设置页配置并绑定,此文件只负责协议细节。
*/
class SelfHostedApiSupport {
  const SelfHostedApiSupport._();

  static Map<String, String> headers({required String apiKey, required String workspaceId}) {
    return {'Authorization': 'Bearer $apiKey', 'X-Workspace-ID': workspaceId, 'Content-Type': 'application/json'};
  }
}
