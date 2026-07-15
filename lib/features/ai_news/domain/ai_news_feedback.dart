import 'ai_news_item.dart';

enum AiNewsFeedbackSignal {
  less(-1),
  more(1);

  const AiNewsFeedbackSignal(this.value);

  final int value;

  static AiNewsFeedbackSignal? fromValue(int value) {
    return values.where((signal) => signal.value == value).firstOrNull;
  }
}

class AiNewsFeedbackEntry {
  const AiNewsFeedbackEntry({
    required this.itemId,
    required this.signal,
    required this.topicKey,
    required this.updatedAt,
  });

  final String itemId;
  final AiNewsFeedbackSignal signal;
  final String topicKey;
  final DateTime updatedAt;
}

class AiNewsInterestProfile {
  const AiNewsInterestProfile({
    this.itemSignals = const {},
    this.topicWeights = const {},
  });

  final Map<String, AiNewsFeedbackSignal> itemSignals;
  final Map<String, int> topicWeights;

  static const empty = AiNewsInterestProfile();
}

String aiNewsTopicKey(AiNewsItem item) => item.category.code;

List<AiNewsItem> rankAiNewsByInterest(
  List<AiNewsItem> items,
  AiNewsInterestProfile profile,
) {
  final ranked = [...items];
  ranked.sort((left, right) {
    final leftDay = DateTime(
      left.publishedAt.year,
      left.publishedAt.month,
      left.publishedAt.day,
    );
    final rightDay = DateTime(
      right.publishedAt.year,
      right.publishedAt.month,
      right.publishedAt.day,
    );
    final dayOrder = rightDay.compareTo(leftDay);
    if (dayOrder != 0) {
      return dayOrder;
    }
    final scoreOrder = _interestScore(right, profile).compareTo(
      _interestScore(left, profile),
    );
    return scoreOrder != 0 ? scoreOrder : right.publishedAt.compareTo(left.publishedAt);
  });
  return ranked;
}

int _interestScore(AiNewsItem item, AiNewsInterestProfile profile) {
  final direct = switch (profile.itemSignals[item.id]) {
    AiNewsFeedbackSignal.less => -1000,
    AiNewsFeedbackSignal.more => 100,
    null => 0,
  };
  return direct + (profile.topicWeights[aiNewsTopicKey(item)] ?? 0) * 20;
}
