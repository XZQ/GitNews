import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_library_providers.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_detail_content.dart';

/* 
*AI 资讯详情页。
*详情页展示已缓存的结构化资讯内容,避免桌面 WebView 直接加载微信 / X 等
*外站时出现白屏。原文仍通过外部浏览器打开。
*作为二级页,顶部统一使用 [AppBar] + [BackButton] 提供返回入口。
*/
class AiNewsDetailPage extends ConsumerWidget {
  const AiNewsDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(aiNewsItemDetailProvider(id));
    // 打开详情即标记已读(幂等、失败静默)。
    ref.listen(aiNewsItemDetailProvider(id), (prev, next) {
      final item = next.valueOrNull;
      if (item != null && prev?.valueOrNull?.id != item.id) {
        ref.read(aiNewsLibraryControllerProvider).markRead(item);
      }
    });
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _back(context)),
        title: Text(l10n.tr('ai_news.detail_title')),
        actions: <Widget>[
          ...async.maybeWhen(
            data: (item) => item == null
                ? <Widget>[]
                : <Widget>[
                    _ReadLaterButton(item: item),
                    IconButton(
                      tooltip: l10n.tr('webview.copy_link'),
                      onPressed: () => _copyLink(context, item),
                      icon: const Icon(Icons.content_copy_rounded),
                    ),
                    IconButton(
                      tooltip: l10n.tr('webview.open_in_browser'),
                      onPressed: () => _openOriginal(context, item),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  ],
            orElse: () => <Widget>[],
          ),
        ],
      ),
      body: async.when(
        data: (item) => item == null ? const _AiNewsDetailMissing() : AiNewsDetailContent(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e.asAppException(),
          onRetry: () => ref.invalidate(aiNewsItemDetailProvider(id)),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    // 正常从列表 push/go 进入时返回上一页;深链/刷新直接进入则兜底回列表。
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/ai_news');
    }
  }

  Future<void> _copyLink(BuildContext context, AiNewsItem item) async {
    final link = item.url.isNotEmpty ? item.url : item.permalink;
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tr('webview.copied'))));
  }

  Future<void> _openOriginal(BuildContext context, AiNewsItem item) async {
    final target = item.url.isNotEmpty ? item.url : item.permalink;
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tr('ai_news.open_failed'))));
    }
  }
}

class _ReadLaterButton extends ConsumerWidget {
  const _ReadLaterButton({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(aiNewsItemStateProvider(item.id)).valueOrNull?.isReadLater ?? false;
    return IconButton(
      tooltip: l10n.tr(saved ? 'ai_news.read_later_remove' : 'ai_news.read_later_add'),
      onPressed: () => _toggle(context, ref),
      icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final added = await ref.read(aiNewsLibraryControllerProvider).toggleReadLater(item);
    if (!context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tr(added ? 'ai_news.read_later_added' : 'ai_news.read_later_removed')),
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
    );
  }
}
