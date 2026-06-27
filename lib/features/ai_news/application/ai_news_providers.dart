import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_ai_news_repository.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';

final aiNewsRepositoryProvider = Provider<AiNewsRepository>((ref) {
  return const LocalAiNewsRepository();
});

final aiNewsDigestProvider = Provider<AiNewsDigest>((ref) {
  return ref.watch(aiNewsRepositoryProvider).getDigest();
});
