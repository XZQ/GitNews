import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/domain/ai_news_enrichment.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_detail_language_content.dart';

void main() {
  test('Chinese source content does not create duplicate bilingual cards', () {
    final content = AiNewsDetailLanguageContent.fromItem(
      _item(
        title: '国务院推进人工智能全学段教育',
        titleEn: '国务院：推进人工智能全学段教育，提升学生人工智能素养',
        summary: '规划要求完善科学教育体系，强化科技教育与人文教育协同。',
      ),
    );

    expect(content.isEnglishArticle, isFalse);
    expect(content.englishOriginal, isNull);
    expect(content.chineseTranslation, isNull);
  });

  test('English source content keeps its original and embedded Chinese translation', () {
    final content = AiNewsDetailLanguageContent.fromItem(
      _item(
        title: 'OpenAI 报告：绘制欧洲 AI 劳动力机遇版图',
        titleEn: "Mapping Europe's AI Workforce Opportunity",
        summary: 'OpenAI 发布新报告，分析 AI 对欧盟就业的影响。',
      ),
    );

    expect(content.isEnglishArticle, isTrue);
    expect(content.englishOriginal, "Mapping Europe's AI Workforce Opportunity");
    expect(content.chineseTranslation, 'OpenAI 发布新报告，分析 AI 对欧盟就业的影响。');
  });

  test('local English feed uses cached enrichment for the Chinese translation', () {
    final item = _item(
      title: 'A safer memory layer for coding agents',
      titleEn: '',
      summary: 'The release supports local storage and encrypted synchronization.',
    );
    final content = AiNewsDetailLanguageContent.fromItem(
      item,
      enrichment: AiNewsEnrichment(
        itemId: item.id,
        generatedSummary: '该版本支持本地存储与加密同步。',
        translatedTitle: '更安全的编程智能体记忆层',
        translatedSummary: '该版本支持本地存储与加密同步，并保持数据可控。',
        importanceScore: 70,
        entities: const AiNewsEntities(),
        model: 'test',
        updatedAt: DateTime(2026, 7, 17),
      ),
    );

    expect(content.isEnglishArticle, isTrue);
    expect(content.englishOriginal, contains('encrypted synchronization'));
    expect(content.chineseTranslation, '该版本支持本地存储与加密同步，并保持数据可控。');
  });
}

AiNewsItem _item({
  required String title,
  required String titleEn,
  required String summary,
}) {
  return AiNewsItem(
    id: 'language-content',
    category: AiNewsCategory.industry,
    title: title,
    titleEn: titleEn,
    summary: summary,
    source: 'Source',
    url: 'https://example.com/article',
    permalink: 'https://example.com/article',
    publishedAt: DateTime(2026, 7, 17),
    score: 70,
    selected: false,
  );
}
