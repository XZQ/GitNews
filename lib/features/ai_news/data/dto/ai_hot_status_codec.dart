import '../../domain/ai_hot_status.dart';
import 'ai_hot_json.dart';

/*
*AI HOT 指纹与版本信息 JSON codec。
*/
class AiHotStatusCodec {
  const AiHotStatusCodec._();

  /* 解码低流量轮询指纹。 */
  static AiHotFingerprint fingerprint(Map<String, Object?> json) {
    return AiHotFingerprint(
      selected: AiHotJson.string(json['selected']),
      all: AiHotJson.string(json['all']),
      docs: AiHotJson.nullableString(json['docs']),
    );
  }

  /* 解码 API 与 Skill 版本信息。 */
  static AiHotVersion version(Map<String, Object?> json) {
    return AiHotVersion(
      apiVersion: AiHotJson.string(json['apiVersion']),
      skillVersion: AiHotJson.string(json['skillVersion']),
      updatedAt: AiHotJson.string(json['updatedAt']),
      changelogUrl: AiHotJson.string(json['changelogUrl']),
      recentChanges: AiHotJson.strings(json['recentChanges']),
    );
  }
}
