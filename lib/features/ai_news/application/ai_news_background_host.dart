import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/platform/desktop_integration_service.dart';
import 'ai_news_background_refresh.dart';

export 'ai_news_background_refresh.dart' show detectNewAiNewsItems, shouldFetchAiHotItems;

const Duration aiNewsBackgroundRefreshInterval = CacheTtlConfig.aiNewsBackgroundRefresh;

/*
*托盘常驻期间的前台进程轮询宿主。
*每 30 分钟先查 AI HOT fingerprint；指纹未变时不下载 items，变化后才写入提醒与系统通知。
*/
class AiNewsBackgroundHost extends ConsumerStatefulWidget {
  const AiNewsBackgroundHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AiNewsBackgroundHost> createState() => _AiNewsBackgroundHostState();
}

class _AiNewsBackgroundHostState extends ConsumerState<AiNewsBackgroundHost> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (DesktopIntegrationService.instance.active) {
      unawaited(_refresh());
      _timer = Timer.periodic(aiNewsBackgroundRefreshInterval, (_) => _refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  /* 所有触发共享刷新器的并发保护与重放逻辑。 */
  Future<void> _refresh() => ref.read(aiNewsBackgroundRefresherProvider).refresh();
}
