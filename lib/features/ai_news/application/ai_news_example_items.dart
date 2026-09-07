import '../data/ai_news_seed_data.dart';
import '../domain/ai_news_item.dart';

/// A read-only fallback for bundled examples; it never marks the remote cache fresh.
AiNewsItem? aiNewsExampleItemById(String id) => AiNewsSeedData.items.where((item) => item.id == id).firstOrNull;

bool isAiNewsExample(AiNewsItem item) => aiNewsExampleItemById(item.id) != null;
