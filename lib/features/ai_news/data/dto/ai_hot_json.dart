import '../../domain/ai_hot_attribution.dart';

/*
*AI HOT DTO 的结构化 JSON 读取工具。
*宽容可选字段缺失,但根节点类型错误仍由上层转为 parse 异常。
*/
class AiHotJson {
  const AiHotJson._();

  /* 将任意 Map 安全转为字符串 key 对象。 */
  static Map<String, Object?>? object(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    return null;
  }

  /* 读取字符串,类型不匹配时回退空串。 */
  static String string(Object? raw) => raw is String ? raw : '';

  /* 读取可空字符串,空串也视为 null。 */
  static String? nullableString(Object? raw) {
    final value = string(raw).trim();
    return value.isEmpty ? null : value;
  }

  /* 读取整数,类型不匹配时回退 0。 */
  static int integer(Object? raw) => raw is num ? raw.toInt() : 0;

  /* 读取 ISO-8601 时间并统一为 UTC。 */
  static DateTime? date(Object? raw) {
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return parsed?.toUtc();
  }

  /* 读取字符串数组。 */
  static List<String> strings(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList(growable: false);
  }

  /* 读取 AI HOT attribution;不完整对象不向领域层伪造。 */
  static AiHotAttribution? attribution(Object? raw) {
    final json = object(raw);
    if (json == null) {
      return null;
    }
    final source = string(json['source']).trim();
    final canonical = string(json['canonical']).trim();
    if (source.isEmpty || canonical.isEmpty) {
      return null;
    }
    return AiHotAttribution(source: source, canonical: canonical);
  }
}
