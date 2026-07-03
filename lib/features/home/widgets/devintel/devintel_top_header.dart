import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';

/// 首页(桌面)顶部条 — 复用 [PageHeader] 体系。
///
/// actions 内部含一个带红点的通知按钮 + 一个脉冲点动画的"实时同步"胶囊。
class DevIntelTopHeader extends StatelessWidget {
  const DevIntelTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      title: l10n.tr('home.title'),
      subtitle: l10n.tr('home.subtitle'),
      searchHint: l10n.tr('home.search_hint'),
      onSearchSubmitted: (v) {
        if (v.trim().isEmpty) return;
        context.go('/trending/repos');
      },
      actions: const [
        _BellWithDot(),
        _LiveSyncBadge(),
      ],
    );
  }
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
