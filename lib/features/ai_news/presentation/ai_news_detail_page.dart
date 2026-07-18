import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../application/ai_news_library_providers.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_detail_action_bar.dart';
import 'widgets/ai_news_detail_content.dart';

/*
*AI 资讯三页详情阅读器。
*
*保持详情在应用壳内,正文只读取本机缓存;原文通过系统浏览器打开。
*/
class AiNewsDetailPage extends ConsumerWidget {
  const AiNewsDetailPage({required this.id, super.key});

  // 资讯 ID。
  final String id;

  @override
  /* 构建详情加载、空、错误与三页内容状态。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(aiNewsItemDetailProvider(id));
    final relatedItems = ref.watch(aiNewsRelatedItemsProvider(id)).valueOrNull ?? const <AiNewsItem>[];
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    ref.listen(aiNewsItemDetailProvider(id), (previous, next) {
      final item = next.valueOrNull;
      if (item != null && previous?.valueOrNull?.id != item.id) {
        ref.read(aiNewsLibraryControllerProvider).markRead(item);
      }
    });
    final item = async.valueOrNull;
    return SecondaryPageScaffold(
      title: l10n.tr('ai_news.detail_title'),
      subtitle: item?.source ?? l10n.tr('common.secondary_page_subtitle'),
      icon: Icons.article_rounded,
      fallbackPath: '/ai_news',
      actions: [
        if (item != null)
          PopupMenuButton<_DetailMenuAction>(
            tooltip: l10n.tr('common.more'),
            onSelected: (action) => _handleMenuAction(context, item, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _DetailMenuAction.copyLink,
                child: ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: Text(l10n.tr('webview.copy_link')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _DetailMenuAction.openOriginal,
                child: ListTile(
                  leading: const Icon(Icons.open_in_browser_rounded),
                  title: Text(l10n.tr('webview.open_in_browser')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
      body: async.when(
        data: (value) => value == null
            ? const _AiNewsDetailMissing()
            : isCompact
                ? AiNewsDetailContent(
                    item: value,
                    relatedItems: relatedItems,
                    onOpenOriginal: () => _openOriginal(context, value),
                    onOpenRelated: (related) => context.pushNamed(
                      'ai_news_detail',
                      pathParameters: {'id': related.id},
                    ),
                    onViewMore: () => context.go('/ai_news'),
                  )
                : Column(
                    children: [
                      AiNewsDetailActionBar(
                        item: value,
                        compact: false,
                        onShare: () => _copyLink(context, value, sharing: true),
                      ),
                      Expanded(
                        child: AiNewsDetailContent(
                          item: value,
                          relatedItems: relatedItems,
                          onOpenOriginal: () => _openOriginal(context, value),
                          onOpenRelated: (related) => context.pushNamed(
                            'ai_news_detail',
                            pathParameters: {'id': related.id},
                          ),
                          onViewMore: () => context.go('/ai_news'),
                        ),
                      ),
                    ],
                  ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error.asAppException(),
          onRetry: () => ref.invalidate(aiNewsItemDetailProvider(id)),
        ),
      ),
      bottomNavigationBar: !isCompact || item == null
          ? null
          : AiNewsDetailActionBar(
              item: item,
              onShare: () => _copyLink(context, item, sharing: true),
            ),
    );
  }

  /* 返回上一页,深链进入时回退到资讯列表。 */
  /* 处理顶部更多菜单。 */
  Future<void> _handleMenuAction(
    BuildContext context,
    AiNewsItem item,
    _DetailMenuAction action,
  ) async {
    switch (action) {
      case _DetailMenuAction.copyLink:
        await _copyLink(context, item);
        return;
      case _DetailMenuAction.openOriginal:
        await _openOriginal(context, item);
        return;
    }
  }

  /* 复制原文链接并显示反馈。 */
  Future<void> _copyLink(
    BuildContext context,
    AiNewsItem item, {
    bool sharing = false,
  }) async {
    final link = item.url.isNotEmpty ? item.url : item.permalink;
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.tr(sharing ? 'ai_news.detail.link_copied' : 'webview.copied'),
        ),
      ),
    );
  }

  /* 在系统浏览器中打开原文。 */
  Future<void> _openOriginal(BuildContext context, AiNewsItem item) async {
    final target = item.url.isNotEmpty ? item.url : item.permalink;
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tr('ai_news.open_failed'))));
    }
  }
}

/*
*详情顶部更多菜单动作。
*/
enum _DetailMenuAction {
  // 复制原文链接。
  copyLink,

  // 打开原文。
  openOriginal,
}

/*
*详情缓存缺失空态。
*/
class _AiNewsDetailMissing extends StatelessWidget {
  const _AiNewsDetailMissing();

  @override
  /* 构建缓存缺失说明。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyView(
      icon: Icons.article_outlined,
      message: l10n.tr('ai_news.detail_missing'),
    );
  }
}
