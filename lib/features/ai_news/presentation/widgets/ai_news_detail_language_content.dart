import '../../domain/ai_news_enrichment.dart';
import '../../domain/ai_news_item.dart';

/*
*详情页双语区块的内容判断结果。
*
*优先使用来源自带的中英文内容,本地 AI 增强只补足缺失的中文翻译。
*/
class AiNewsDetailLanguageContent {
  const AiNewsDetailLanguageContent({
    required this.isEnglishArticle,
    this.englishOriginal,
    this.chineseTranslation,
  });

  /* 从条目与可选增强结果提取需要展示的双语内容。 */
  factory AiNewsDetailLanguageContent.fromItem(
    AiNewsItem item, {
    AiNewsEnrichment? enrichment,
  }) {
    final title = item.title.trim();
    final titleEn = item.titleEn.trim();
    final summary = item.summary.trim();
    final isEnglishArticle = _isEnglishDominant(titleEn) || _isEnglishDominant(title) || (_isEnglishDominant(summary) && !_isChineseContent(title));
    if (!isEnglishArticle) {
      return const AiNewsDetailLanguageContent(
        isEnglishArticle: false,
        englishOriginal: null,
      );
    }

    final englishTitle = _isEnglishDominant(title)
        ? title
        : _isEnglishDominant(titleEn)
            ? titleEn
            : null;
    final englishSummary = _isEnglishDominant(summary) ? summary : null;
    final englishOriginal = englishTitle != null && englishSummary != null && englishSummary != englishTitle ? '$englishTitle\n\n$englishSummary' : englishTitle ?? englishSummary;
    final chineseTranslation = _firstChineseContent([
      summary,
      enrichment?.translatedSummary,
      enrichment?.generatedSummary,
      title,
      enrichment?.translatedTitle,
    ]);
    return AiNewsDetailLanguageContent(
      isEnglishArticle: isEnglishArticle,
      englishOriginal: englishOriginal,
      chineseTranslation: chineseTranslation,
    );
  }

  // 当前条目是否具有可识别的英文原文。
  final bool isEnglishArticle;

  // 英文原文内容,中文条目为 null。
  final String? englishOriginal;

  // 中文翻译内容,来源与增强均未提供时为 null。
  final String? chineseTranslation;
}

/* 返回候选内容中首段以中文为主的文本。 */
String? _firstChineseContent(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (_isChineseContent(value)) {
      return value;
    }
  }
  return null;
}

/* 判断文本是否以英文字符为主,避免把包含少量英文缩写的中文误判为英文。 */
bool _isEnglishDominant(String value) {
  final latinCount = RegExp(r'[A-Za-z]').allMatches(value).length;
  final hanCount = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]').allMatches(value).length;
  return latinCount >= 2 && (hanCount == 0 || latinCount > hanCount * 2);
}

/* 判断文本是否包含足够中文且不是英文占主导。 */
bool _isChineseContent(String value) {
  final hanCount = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]').allMatches(value).length;
  return hanCount >= 2 && !_isEnglishDominant(value);
}
