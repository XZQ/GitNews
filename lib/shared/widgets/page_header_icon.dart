import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/* 
*主页面 Header 的统一图标块。
*工具风基线:中性纸面圆角块 + hairline 边框 + 主色图标,不再用渐变与投影
*(渐变+浮影是"营销页"观感的主要来源,且与冷静工具风冲突)。
*/
class PageHeaderIcon extends StatelessWidget {
  const PageHeaderIcon({required this.icon, this.accent, super.key});

  final IconData icon;

  // 主色,跟随当前预设;不传则与主题 primary 一致。
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = accent ?? colors.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: a.withValues(alpha: colors.brightness == Brightness.light ? 0.1 : 0.18),
        border: Border.all(color: a.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Icon(icon, color: a, size: 20),
    );
  }
}
