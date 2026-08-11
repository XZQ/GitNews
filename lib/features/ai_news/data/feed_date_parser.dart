/*
*feed 日期解析(纯函数,便于单测)。
*
*统一支持 Atom 的 ISO-8601 与 RSS 的 RFC-822 两种格式,返回值一律转为
*  UTC;解析失败返回 null,由调用方决定兜底时刻。
*/

/*
*解析 feed 日期:先试 ISO-8601(Atom),再试 RFC-822(RSS)。
*返回 UTC;解析失败返回 null 由调用方兜底。
*/
DateTime? parseFeedDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return null;
  }
  final iso = DateTime.tryParse(s);
  if (iso != null) {
    return iso.toUtc();
  }
  return parseRfc822Date(s);
}

const Map<String, int> _kMonths = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, // -
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/*
*RFC-822 日期解析(RSS pubDate),如 `Sat, 18 Apr 2026 00:00:00 -0400`。
*支持数字时区偏移与 GMT/UT/UTC/Z;其他命名时区按 UTC 处理(误差可接受,
*资讯按天分组展示)。无法解析返回 null。
*/
DateTime? parseRfc822Date(String raw) {
  final match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\w*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{1,4})?').firstMatch(raw);
  if (match == null) {
    return null;
  }
  final month = _kMonths[match.group(2)!.toLowerCase()];
  if (month == null) {
    return null;
  }
  var year = int.parse(match.group(3)!);
  if (year < 100) {
    year += year >= 70 ? 1900 : 2000;
  }
  final utc = DateTime.utc(year, month, int.parse(match.group(1)!), int.parse(match.group(4)!), int.parse(match.group(5)!), int.parse(match.group(6) ?? '0'));
  final zone = match.group(7) ?? '';
  final numeric = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
  if (numeric == null) {
    // GMT/UT/UTC/Z 及未知命名时区一律按 UTC。
    return utc;
  }
  final sign = numeric.group(1) == '-' ? -1 : 1;
  final offset = Duration(hours: int.parse(numeric.group(2)!), minutes: int.parse(numeric.group(3)!));
  return utc.subtract(offset * sign);
}
