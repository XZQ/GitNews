import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/*
*趋势看板分类选择器(全部 / Agent / MCP / AI Coding / 新晋项目)。
*从 trending_desktop_view 拆出,保持主视图文件 < 300 行(AGENTS.md)。
*文案在 build 时按 value 插值取 l10n key(trending.board.<value>)。
*/
class TrendingBoardSelector extends StatelessWidget {
  const TrendingBoardSelector({required this.value, required this.onChanged, super.key});

  final String value;
  final ValueChanged<String> onChanged;

  static const _items = [
    _TrendingBoardOption(value: 'all', icon: Icons.grid_view_rounded),
    _TrendingBoardOption(value: 'agent', icon: Icons.auto_awesome_rounded),
    _TrendingBoardOption(value: 'mcp', icon: Icons.hub_rounded),
    _TrendingBoardOption(value: 'ai_coding', icon: Icons.terminal_rounded),
    _TrendingBoardOption(value: 'new_repos', icon: Icons.new_releases_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in _items)
          ChoiceChip(
            selected: value == item.value,
            showCheckmark: false,
            avatar: Icon(item.icon, size: 16),
            label: Text(l10n.tr('trending.board.${item.value}')),
            onSelected: (_) {
              if (value != item.value) {
                onChanged(item.value);
              }
            },
          ),
      ],
    );
  }
}

class _TrendingBoardOption {
  const _TrendingBoardOption({required this.value, required this.icon});

  final String value;
  final IconData icon;
}
