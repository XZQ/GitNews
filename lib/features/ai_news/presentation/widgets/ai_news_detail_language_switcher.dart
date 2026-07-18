import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'ai_news_detail_components.dart';

/*
*资讯详情的双语正文切换器。
*
*切换仅影响当前阅读会话,默认使用设计稿中的中英对照模式。
*/
class AiNewsDetailLanguageSwitcher extends StatefulWidget {
  const AiNewsDetailLanguageSwitcher({
    required this.englishOriginal,
    this.chineseTranslation,
    super.key,
  });

  // 英文原文。
  final String englishOriginal;

  // 中文翻译,缺失时展示可生成提示。
  final String? chineseTranslation;

  @override
  /* 创建当前页面私有的语种选择状态。 */
  State<AiNewsDetailLanguageSwitcher> createState() => _AiNewsDetailLanguageSwitcherState();
}

/*
*管理中文、英文和对照三种阅读状态。
*/
class _AiNewsDetailLanguageSwitcherState extends State<AiNewsDetailLanguageSwitcher> {
  // 当前语种模式。
  _DetailLanguageMode _mode = _DetailLanguageMode.comparison;

  @override
  /* 构建设计稿中的正文标签、分段切换和双语阅读区。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final showEnglish = _mode != _DetailLanguageMode.chinese;
    final showChinese = _mode != _DetailLanguageMode.english;
    final isComparison = _mode == _DetailLanguageMode.comparison;
    final bodyStyle = AppTypography.reading(AppTypography.bodyLarge).copyWith(
      fontSize: AppTypography.titleMedium.fontSize,
      height: 1.9,
      color: colors.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.tr('ai_news.detail.body'),
              style: AppTypography.reading(
                AppTypography.labelMicro,
              ).copyWith(color: aiNewsDetailMutedColor(context)),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LanguageSegment(
                    key: const ValueKey('ai-news-language-chinese'),
                    label: l10n.tr('ai_news.detail.language_chinese'),
                    selected: _mode == _DetailLanguageMode.chinese,
                    onTap: () => _select(_DetailLanguageMode.chinese),
                  ),
                  _LanguageSegment(
                    key: const ValueKey('ai-news-language-english'),
                    label: l10n.tr('ai_news.detail.language_english'),
                    selected: _mode == _DetailLanguageMode.english,
                    onTap: () => _select(_DetailLanguageMode.english),
                  ),
                  _LanguageSegment(
                    key: const ValueKey('ai-news-language-comparison'),
                    label: l10n.tr('ai_news.detail.language_comparison'),
                    selected: isComparison,
                    onTap: () => _select(_DetailLanguageMode.comparison),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showEnglish) ...[
          const SizedBox(height: AppSpacing.lg),
          if (isComparison) ...[
            Text(
              'EN · ${l10n.tr('ai_news.detail.original')}',
              style: AppTypography.reading(
                AppTypography.labelMicro,
              ).copyWith(color: aiNewsDetailMutedColor(context)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            widget.englishOriginal,
            style: bodyStyle.copyWith(
              fontSize: 15.75,
              height: 1.88,
              color: isComparison ? aiNewsDetailSecondaryColor(context) : colors.onSurface,
            ),
          ),
        ],
        if (showChinese) ...[
          const SizedBox(height: AppSpacing.lg),
          if (isComparison) ...[
            Text(
              '中 · ${l10n.tr('ai_news.detail.translation')}',
              style: AppTypography.reading(
                AppTypography.labelMicro,
              ).copyWith(color: aiNewsDetailMutedColor(context)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            widget.chineseTranslation ?? l10n.tr('ai_news.detail.translation_unavailable'),
            style: bodyStyle,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          '// ${l10n.tr('ai_news.detail.translation_note')}',
          style: AppTypography.reading(
            AppTypography.labelSmall,
          ).copyWith(color: aiNewsDetailMutedColor(context)),
        ),
      ],
    );
  }

  /* 切换语种并保留当前滚动位置。 */
  void _select(_DetailLanguageMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
  }
}

/*
*正文语种分段中的单个按钮。
*/
class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  // 按钮文案。
  final String label;

  // 是否为当前语种。
  final bool selected;

  // 切换操作。
  final VoidCallback onTap;

  @override
  /* 构建紧凑且可键盘聚焦的分段按钮。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md2,
              vertical: AppSpacing.xs2,
            ),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
*详情正文的三种本地阅读模式。
*/
enum _DetailLanguageMode {
  // 仅中文。
  chinese,

  // 仅英文。
  english,

  // 中英文对照。
  comparison,
}
