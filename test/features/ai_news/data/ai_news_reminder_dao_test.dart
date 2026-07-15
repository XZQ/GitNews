import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/ai_news/data/ai_news_reminder_dao.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('reminders persist, deduplicate and support read state', () async {
    final database = await LocalDatabase.openInMemory();
    addTearDown(database.close);
    final dao = AiNewsReminderDao(database.executor);
    final now = DateTime.utc(2026, 7, 16, 12);
    final item = _item(now);

    await dao.addItems([item, item], now: now);
    var reminders = await dao.readAll();
    expect(reminders, hasLength(1));
    expect(reminders.single.isRead, isFalse);

    await dao.markRead(item.id, now: now.add(const Duration(minutes: 1)));
    reminders = await dao.readAll();
    expect(reminders.single.isRead, isTrue);
  });
}

AiNewsItem _item(DateTime publishedAt) {
  return AiNewsItem(
    id: 'item-1',
    category: AiNewsCategory.industry,
    title: 'New AI release',
    titleEn: '',
    summary: '',
    source: 'source',
    url: '',
    permalink: '',
    publishedAt: publishedAt,
    score: 0,
    selected: false,
  );
}
