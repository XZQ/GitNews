String projectContributorsCacheKey({
  required Iterable<String> repos,
  required String cacheScope,
}) {
  final sorted = repos.toSet().toList()..sort();
  return 'project:github:contributors:v2:${_stableHash('$cacheScope|${sorted.join('|')}')}';
}

String _stableHash(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash.toRadixString(16);
}
