String projectContributorsCacheKey({
  required Iterable<String> repos,
  required String cacheScope,
}) {
  return _projectCacheKey(
    namespace: 'contributors:v2',
    repos: repos,
    cacheScope: cacheScope,
  );
}

String projectActivitiesCacheKey({
  required Iterable<String> repos,
  required String cacheScope,
}) {
  return _projectCacheKey(
    namespace: 'activities:v1',
    repos: repos,
    cacheScope: cacheScope,
  );
}

String _projectCacheKey({
  required String namespace,
  required Iterable<String> repos,
  required String cacheScope,
}) {
  final sorted = repos.toSet().toList()..sort();
  return 'project:github:$namespace:${_stableHash('$cacheScope|${sorted.join('|')}')}';
}

String _stableHash(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash.toRadixString(16);
}
