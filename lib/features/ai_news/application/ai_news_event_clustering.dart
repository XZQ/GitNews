import '../domain/ai_news_item.dart';

class AiNewsEventCluster {
  const AiNewsEventCluster({required this.primary, required this.items});

  final AiNewsItem primary;
  final List<AiNewsItem> items;

  List<String> get sources => items.map((item) => item.source).toSet().toList();
}

/*
*按标题词元相似度和时间窗合并多源报道。算法完全本地、确定性运行；
*单条事件也以 cluster 返回，便于 UI 统一渲染。
*/
List<AiNewsEventCluster> clusterAiNewsEvents(
  List<AiNewsItem> items, {
  Duration timeWindow = const Duration(hours: 48),
  double similarityThreshold = 0.52,
}) {
  final clusters = <List<AiNewsItem>>[];
  for (final item in items) {
    final tokens = _titleTokens(item.title.isEmpty ? item.titleEn : item.title);
    List<AiNewsItem>? match;
    for (final cluster in clusters) {
      final candidate = cluster.first;
      final distance = item.publishedAt.difference(candidate.publishedAt).abs();
      if (distance > timeWindow) {
        continue;
      }
      final candidateTokens = _titleTokens(
        candidate.title.isEmpty ? candidate.titleEn : candidate.title,
      );
      if (_jaccard(tokens, candidateTokens) >= similarityThreshold) {
        match = cluster;
        break;
      }
    }
    (match ?? (clusters..add(<AiNewsItem>[])).last).add(item);
  }

  final result = [
    for (final cluster in clusters) AiNewsEventCluster(primary: _primary(cluster), items: List.unmodifiable(cluster)),
  ];
  result.sort(
    (left, right) => right.primary.publishedAt.compareTo(left.primary.publishedAt),
  );
  return result;
}

AiNewsItem _primary(List<AiNewsItem> items) {
  final sorted = [...items]..sort((left, right) {
      final score = right.score.compareTo(left.score);
      return score != 0 ? score : right.publishedAt.compareTo(left.publishedAt);
    });
  return sorted.first;
}

Set<String> _titleTokens(String title) {
  final normalized = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), ' ');
  final result = <String>{};
  for (final match in RegExp(r'[a-z0-9]+|[\u4e00-\u9fff]+').allMatches(normalized)) {
    final token = match.group(0)!;
    if (_stopWords.contains(token)) {
      continue;
    }
    if (RegExp(r'^[\u4e00-\u9fff]+$').hasMatch(token) && token.length > 2) {
      for (var index = 0; index < token.length - 1; index++) {
        result.add(token.substring(index, index + 2));
      }
    } else if (token.length > 1) {
      result.add(token);
    }
  }
  return result;
}

double _jaccard(Set<String> left, Set<String> right) {
  if (left.isEmpty || right.isEmpty) {
    return 0;
  }
  final intersection = left.intersection(right).length;
  final union = left.union(right).length;
  return intersection / union;
}

const _stopWords = {'the', 'a', 'an', 'and', 'for', 'with', 'to', 'of', 'in', 'ai'};
