import '../../domain/ai_hot_topic.dart';
import 'ai_hot_json.dart';

/*
*AI HOT 当前热点 JSON codec。
*/
class AiHotTopicCodec {
  const AiHotTopicCodec._();

  /* 解码热点列表。 */
  static List<AiHotTopic> list(Map<String, Object?> json) {
    final raw = json['items'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (AiHotJson.object(item) case final Map<String, Object?> value)
          AiHotTopic(
            id: AiHotJson.string(value['id']),
            title: AiHotJson.string(value['title']),
            url: AiHotJson.string(value['url']),
            permalink: AiHotJson.string(value['permalink']),
            source: AiHotJson.string(value['source']),
            sourceCount: AiHotJson.integer(value['sourceCount']),
            signalCount: AiHotJson.integer(value['signalCount']),
            sourceNames: AiHotJson.strings(value['sourceNames']),
            latestAt: AiHotJson.date(value['latestAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
    ];
  }
}
