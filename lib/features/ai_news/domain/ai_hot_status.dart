/*
*AI HOT 低流量轮询指纹。
*值为不透明字符串,只用于对比是否变化。
*/
class AiHotFingerprint {
  const AiHotFingerprint({required this.selected, required this.all, this.docs});

  // 精选流头部指纹。
  final String selected;

  // 公开池头部指纹。
  final String all;

  // 接入文档链接。
  final String? docs;
}

/*
*AI HOT API 与 Skill 版本信息。
*/
class AiHotVersion {
  const AiHotVersion({
    required this.apiVersion,
    required this.skillVersion,
    required this.updatedAt,
    required this.changelogUrl,
    required this.recentChanges,
  });

  // REST API 合同版本。
  final String apiVersion;

  // AI HOT Skill 版本。
  final String skillVersion;

  // 版本更新日期。
  final String updatedAt;

  // 完整变更日志链接。
  final String changelogUrl;

  // 最近用户可感知变更。
  final List<String> recentChanges;
}
