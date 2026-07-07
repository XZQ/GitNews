import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_providers.dart';
import 'widgets/ai_news_detail_content.dart';

/* AI 资讯详情页。 */
/*  */
/* 详情页展示已缓存的结构化资讯内容,避免桌面 WebView 直接加载微信 / X 等 */
/* 外站时出现白屏。原文仍通过外部浏览器打开。 */
class AiNewsDetailPage extends ConsumerWidget {
  const AiNewsDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aiNewsItemDetailProvider(id));
    return Scaffold(
      body: async.when(
        data: (item) => item == null
            ? const _AiNewsDetailMissing()
            : AiNewsDetailContent(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e.asAppException(),
          onRetry: () => ref.invalidate(aiNewsItemDetailProvider(id)),
        ),
      ),
    );
  }
}

class _AiNewsDetailMissing extends StatelessWidget {
  const _AiNewsDetailMissing();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyView(
      icon: Icons.article_outlined,
      message: l10n.tr('ai_news.detail_missing'),
      action: FilledButton.icon(
        onPressed: () => context.go('/ai_news'),
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l10n.tr('common.back')),
      ),
    );
  }
}
