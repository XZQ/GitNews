import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/ai_news_feedback_dao.dart';
import '../domain/ai_news_feedback.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_providers.dart';

final aiNewsFeedbackDaoProvider = Provider<AiNewsFeedbackDao>(
  (ref) => AiNewsFeedbackDao(ref.watch(appDatabaseProvider).executor),
);

final aiNewsInterestProfileProvider = FutureProvider<AiNewsInterestProfile>(
  (ref) async {
    final entries = await ref.watch(aiNewsFeedbackDaoProvider).readAll();
    final signals = <String, AiNewsFeedbackSignal>{};
    final weights = <String, int>{};
    for (final entry in entries) {
      signals[entry.itemId] = entry.signal;
      weights.update(
        entry.topicKey,
        (value) => value + entry.signal.value,
        ifAbsent: () => entry.signal.value,
      );
    }
    return AiNewsInterestProfile(
      itemSignals: signals,
      topicWeights: weights,
    );
  },
);

final aiNewsFeedbackControllerProvider = Provider<AiNewsFeedbackController>(
  AiNewsFeedbackController.new,
);

class AiNewsFeedbackController {
  const AiNewsFeedbackController(this._ref);

  final Ref _ref;

  Future<void> set(AiNewsItem item, AiNewsFeedbackSignal signal) async {
    await _ref.read(aiNewsFeedbackDaoProvider).set(
          AiNewsFeedbackEntry(
            itemId: item.id,
            signal: signal,
            topicKey: aiNewsTopicKey(item),
            updatedAt: _ref.read(clockProvider)().toUtc(),
          ),
        );
    _ref.invalidate(aiNewsInterestProfileProvider);
  }

  Future<void> clear(AiNewsItem item) async {
    await _ref.read(aiNewsFeedbackDaoProvider).remove(item.id);
    _ref.invalidate(aiNewsInterestProfileProvider);
  }
}
