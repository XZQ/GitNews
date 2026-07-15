import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/ai_news/data/ai_news_feedback_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('feedback persists and influences same-day ranking', () async {
    final db = await LocalDatabase.openInMemory();
    addTearDown(db.close);
    final dao = AiNewsFeedbackDao(db.executor);
    final now = DateTime.utc(2026, 7, 16, 12);
    await dao.set(
      AiNewsFeedbackEntry(
        itemId: 'paper',
        signal: AiNewsFeedbackSignal.more,
        topicKey: AiNewsCategory.paper.code,
        updatedAt: now,
      ),
    );

    final entries = await dao.readAll();
    final profile = AiNewsInterestProfile(
      itemSignals: {entries.single.itemId: entries.single.signal},
      topicWeights: {entries.single.topicKey: entries.single.signal.value},
    );
    final ranked = rankAiNewsByInterest(
      [
        _item('model', AiNewsCategory.aiModels, now),
        _item('paper', AiNewsCategory.paper, now.subtract(const Duration(hours: 1))),
      ],
      profile,
    );

    expect(ranked.first.id, 'paper');
    await dao.remove('paper');
    expect(await dao.readAll(), isEmpty);
  });
}

AiNewsItem _item(String id, AiNewsCategory category, DateTime publishedAt) {
  return AiNewsItem(
    id: id,
    category: category,
    title: id,
    titleEn: '',
    summary: '',
    source: '',
    url: '',
    permalink: '',
    publishedAt: publishedAt,
    score: 0,
    selected: false,
  );
}
