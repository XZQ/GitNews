/*
*AI HOT 返回的署名与 canonical 反链。
*/
class AiHotAttribution {
  const AiHotAttribution({required this.source, required this.canonical});

  // 聚合方署名。
  final String source;

  // AI HOT 站内规范链接。
  final String canonical;
}
