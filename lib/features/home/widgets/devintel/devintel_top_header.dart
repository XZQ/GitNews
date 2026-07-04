import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai_news/application/ai_news_providers.dart';
import '../../../monitor/application/monitor_providers.dart';
import '../../../project/application/project_providers.dart';
import '../../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../trending/application/trending_providers.dart';
import '../../../../shared/widgets/page_header.dart';

/// 首页(桌面)顶部条 — 复用 [PageHeader] 体系。
///
/// actions 内部含一个带红点的通知按钮 + 一个脉冲点动画的"实时同步"胶囊。
class DevIntelTopHeader extends ConsumerWidget {
  const DevIntelTopHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      title: l10n.tr('home.title'),
      subtitle: l10n.tr('home.subtitle'),
      searchHint: l10n.tr('home.search_hint'),
      onSearchSubmitted: (v) => _openGlobalSearch(context, ref, v),
      actions: const [
        _BellWithDot(),
        _LiveSyncBadge(),
      ],
    );
  }
}

void _openGlobalSearch(BuildContext context, WidgetRef ref, String rawQuery) {
  final query = rawQuery.trim();
  if (query.isEmpty) return;

  final normalized = query.toLowerCase();
  if (_containsAny(normalized, const [
    'ai',
    'openai',
    'anthropic',
    'gemini',
    '模型',
    '资讯',
    '新闻',
    '论文',
  ])) {
    ref.read(aiNewsSearchQueryProvider.notifier).state = query;
    context.go('/ai_news');
    return;
  }

  if (_containsAny(normalized, const [
    'agent',
    'mcp',
    'coding',
    'rag',
    '智能体',
    '雷达',
    '本地推理',
  ])) {
    ref.read(techHotspotSearchQueryProvider.notifier).state = query;
    context.go('/tech_hotspot');
    return;
  }

  if (_containsAny(normalized, const [
    'monitor',
    'alert',
    '告警',
    '监控',
    '规则',
  ])) {
    ref.read(monitorSearchQueryProvider.notifier).state = query;
    context.go('/monitor');
    return;
  }

  if (_containsAny(normalized, const [
    'report',
    '报告',
    '周报',
    '贡献者',
    'developer',
    'contributor',
  ])) {
    ref.read(projectSearchQueryProvider.notifier).state = query;
    context.go('/project');
    return;
  }

  ref.read(trendingSearchQueryProvider.notifier).state = query;
  context.go('/trending');
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return IconButton(
      onPressed: () => context.go('/monitor'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          const Positioned(
            right: -2,
            top: -2,
            child: _Dot(),
          ),
        ],
      ),
      tooltip: l10n.tr('home.monitor_center'),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      );
}

/// HeaderStatPill 在 devintel 上下文中需要 const 构造,但带 BoxShadow 的 dot
/// 无法直接 const;保留此 type 以便后续接入脉冲动画。

/// 实时同步胶囊(带脉冲点)。
class _LiveSyncBadge extends StatelessWidget {
  const _LiveSyncBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeaderStatPill(
      icon: Icons.circle,
      label: l10n.tr('home.live_sync'),
      color: AppColors.success,
    );
  }
}
