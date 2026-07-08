import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';

/* 
*应用内 WebView 页面。
*顶层路由 `/webview`(脱离 [StatefulShellRoute] / 侧栏),全屏浏览外链;
*顶栏提供「刷新 / 在浏览器中打开 / 复制链接 / 返回」,顶栏下方进度条提示加载进度。
*Windows 平台依赖 WebView2 运行时(现代 Win10/11 已预装)。
*/
class WebViewPage extends StatefulWidget {
  const WebViewPage({required this.url, this.title, super.key});

  final String url;
  final String? title;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;
  String _pageTitle = '';
  int _progress = 0;
  bool _canGoBack = false;
  bool _failed = false;
  bool _hasLoadedAnyContent = false;

  // 移动端 Chrome UA。
  // Windows WebView2 默认是桌面 Edge UA,会被微信公众号 / 部分媒体站点拦截
  // 返回 403 / 空内容,导致主帧加载失败。改成 Android Chrome 移动 UA 后,
  // 多数站点返回适合内嵌阅读的移动版页面。
  static const String _mobileUa =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, '
      'like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  @override
  void dispose() {
    // Windows 下 WebView2 不显式 dispose 会残留进程并在退出时崩溃。
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.tryParse(widget.url);
    // 仅允许 http/https,拒绝 javascript: / file: / blob: / data: 等 scheme
    // (CWE-939):否则应用内 WebView 可被构造为执行任意 JS 或读沙箱文件。
    final urlInvalid = widget.url.isEmpty || uri == null || !_isHttpScheme(uri);
    final title = widget.title?.isNotEmpty == true ? widget.title! : _pageTitle;
    return Scaffold(
      appBar: _WebViewAppBar(
        title: title,
        host: _hostFromUrl(widget.url),
        urlInvalid: urlInvalid,
        onBack: _onBack,
        onRefresh: _retry,
        onOpenInBrowser: _openInBrowser,
        onCopyLink: _copyLink,
      ),
      body: urlInvalid
          ? EmptyView(
              icon: Icons.link_off_rounded,
              message: l10n.tr('webview.invalid'),
            )
          : _WebViewBody(state: this),
    );
  }

  Future<void> _onBack() async {
    if (_canGoBack && _controller != null) {
      await _controller!.goBack();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !_isHttpScheme(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('webview.copied'))),
    );
  }

  void _retry() {
    setState(() {
      _failed = false;
      _hasLoadedAnyContent = false;
      _progress = 0;
    });
    _controller?.reload();
  }

  // WebView 回调入口:集中调用 setState,避免在外部 Widget 中触发 protected 警告。
  void onTitleChanged(String? t) {
    if (!mounted) return;
    setState(() => _pageTitle = t ?? '');
  }

  void onProgressChanged(int progress) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      if (progress > 0 && progress < 100) _failed = false;
      if (progress > 30) _hasLoadedAnyContent = true;
    });
  }

  void onLoadStopFinished(bool canBack) {
    if (!mounted) return;
    setState(() {
      _canGoBack = canBack;
      _failed = false;
      _hasLoadedAnyContent = true;
    });
  }

  void onMainFrameError() {
    if (!mounted) return;
    if (_hasLoadedAnyContent) return;
    setState(() => _failed = true);
  }

  static String _hostFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : (uri?.authority ?? url);
  }

  /* 
  *仅允许 http/https scheme(防御开放重定向 / file:// 读沙箱 / javascript: 注入)。
  */
  static bool _isHttpScheme(Uri uri) =>
      uri.scheme == 'http' || uri.scheme == 'https';
}

class _WebViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _WebViewAppBar({
    required this.title,
    required this.host,
    required this.urlInvalid,
    required this.onBack,
    required this.onRefresh,
    required this.onOpenInBrowser,
    required this.onCopyLink,
  });

  final String title;
  final String host;
  final bool urlInvalid;
  final Future<void> Function() onBack;
  final VoidCallback onRefresh;
  final Future<void> Function() onOpenInBrowser;
  final Future<void> Function() onCopyLink;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      leading: BackButton(onPressed: onBack),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.isNotEmpty ? title : host,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium,
          ),
          Text(
            host,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: l10n.tr('webview.refresh'),
          icon: const Icon(Icons.refresh_rounded),
          onPressed: urlInvalid ? null : onRefresh,
        ),
        IconButton(
          tooltip: l10n.tr('webview.open_in_browser'),
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: onOpenInBrowser,
        ),
        PopupMenuButton<String>(
          tooltip: l10n.tr('webview.more'),
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) {
            if (v == 'copy') onCopyLink();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'copy',
              child: Text(l10n.tr('webview.copy_link')),
            ),
          ],
        ),
      ],
    );
  }
}

/* 
*WebView 主体 + 进度条 / 错误覆盖层。
*持有 [_WebViewPageState] 引用以便回调 [State.setState] 与控制器赋值。
*两个类均私有于本文件,耦合可控。
*/
class _WebViewBody extends StatelessWidget {
  const _WebViewBody({required this.state});

  final _WebViewPageState state;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    // InAppWebView 常驻:错误态用 ErrorView 覆盖层叠加,而非替换控件,
    // 避免错误↔内容切换时销毁并重建 WebView2(丢失滚动/加载进度,且重建有进程开销)。
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: true,
            allowsInlineMediaPlayback: true,
            iframeAllow: 'fullscreen',
            userAgent: _WebViewPageState._mobileUa,
          ),
          onWebViewCreated: (controller) => state._controller = controller,
          onTitleChanged: (controller, t) => state.onTitleChanged(t),
          onProgressChanged: (_, progress) =>
              state.onProgressChanged(progress),
          onLoadStop: (controller, _) async {
            final canBack = await controller.canGoBack();
            state.onLoadStopFinished(canBack);
          },
          onReceivedError: (controller, request, error) {
            // 子资源(图片 / CSS)错误也会回调,只对主帧致命错误置失败。
            final isMainFrame = request.url.toString() == widget.url ||
                request.isForMainFrame == true;
            if (!isMainFrame) return;
            state.onMainFrameError();
          },
        ),
        if (state._progress > 0 && state._progress < 100 && !state._failed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: state._progress / 100,
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
          ),
        if (state._failed)
          ErrorView(
            error: const AppException(kind: AppExceptionKind.network),
            onRetry: state._retry,
          ),
      ],
    );
  }
}
