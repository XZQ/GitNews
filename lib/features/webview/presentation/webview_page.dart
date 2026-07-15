import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';

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

  static const String _mobileUa = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, '
      'like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.tryParse(widget.url);
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
      body: urlInvalid ? EmptyView(icon: Icons.link_off_rounded, message: l10n.tr('webview.invalid')) : _WebViewBody(state: this),
    );
  }

  Future<void> _onBack() async {
    if (_canGoBack && _controller != null) {
      await _controller!.goBack();
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !_isHttpScheme(uri)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tr('webview.copied'))));
  }

  void _retry() {
    setState(() {
      _failed = false;
      _hasLoadedAnyContent = false;
      _progress = 0;
    });
    _controller?.reload();
  }

  void onTitleChanged(String? t) {
    if (!mounted) {
      return;
    }
    setState(() => _pageTitle = t ?? '');
  }

  void onProgressChanged(int progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = progress;
      if (progress > 0 && progress < 100) {
        _failed = false;
      }
      if (progress > 30) {
        _hasLoadedAnyContent = true;
      }
    });
  }

  void onLoadStopFinished(bool canBack) {
    if (!mounted) {
      return;
    }
    setState(() {
      _canGoBack = canBack;
      _failed = false;
      _hasLoadedAnyContent = true;
    });
  }

  void onMainFrameError() {
    if (!mounted) {
      return;
    }
    if (_hasLoadedAnyContent) {
      return;
    }
    setState(() => _failed = true);
  }

  static String _hostFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : (uri?.authority ?? url);
  }

  static bool _isHttpScheme(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';
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
              style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
            )
          ],
        ),
        actions: [
          IconButton(tooltip: l10n.tr('webview.refresh'), icon: const Icon(Icons.refresh_rounded), onPressed: urlInvalid ? null : onRefresh),
          IconButton(tooltip: l10n.tr('webview.open_in_browser'), icon: const Icon(Icons.open_in_new_rounded), onPressed: onOpenInBrowser),
          PopupMenuButton<String>(
              tooltip: l10n.tr('webview.more'),
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'copy') {
                  onCopyLink();
                }
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'copy', child: Text(l10n.tr('webview.copy_link')))])
        ]);
  }
}

class _WebViewBody extends StatelessWidget {
  const _WebViewBody({required this.state});

  final _WebViewPageState state;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    return Stack(children: [
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
          onProgressChanged: (_, progress) => state.onProgressChanged(progress),
          onLoadStop: (controller, _) async {
            final canBack = await controller.canGoBack();
            state.onLoadStopFinished(canBack);
          },
          onReceivedError: (controller, request, error) {
            final isMainFrame = request.url.toString() == widget.url || request.isForMainFrame == true;
            if (!isMainFrame) {
              return;
            }
            state.onMainFrameError();
          }),
      if (state._progress > 0 && state._progress < 100 && !state._failed)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(value: state._progress / 100, minHeight: 2, backgroundColor: Colors.transparent),
        ),
      if (state._failed) ErrorView(error: const AppException(kind: AppExceptionKind.network), onRetry: state._retry)
    ]);
  }
}
