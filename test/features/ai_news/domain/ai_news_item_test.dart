import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('Chinese locale uses title and other locales default to titleEn', () {
    final item = _item(title: '中文标题', titleEn: 'English title');

    expect(item.titleForLanguage('zh-CN'), '中文标题');
    expect(item.titleForLanguage('en-US'), 'English title');
    expect(item.titleForLanguage('ja-JP'), 'English title');
    expect(item.titleForLanguage(null), 'English title');
  });

  test('localized title falls back when the preferred field is empty', () {
    expect(_item(title: '', titleEn: 'English title').titleForLanguage('zh'), 'English title');
    expect(_item(title: '中文标题', titleEn: '').titleForLanguage('en'), '中文标题');
  });
}

AiNewsItem _item({required String title, required String titleEn}) {
  return AiNewsItem(
    id: 'localized-title',
    category: AiNewsCategory.industry,
    title: title,
    titleEn: titleEn,
    summary: '',
    source: 'source',
    url: '',
    permalink: '',
    publishedAt: DateTime.utc(2026, 7, 19),
    score: 0,
    selected: false,
  );
}
