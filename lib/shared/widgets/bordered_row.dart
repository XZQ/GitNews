import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/* 
*共享外边框的横向多卡容器(方案 1:纯外框)。
*替代"每张卡各自带 Border.all + 卡间 SizedBox 间距"的旧模式 ——
*后者会在相邻卡边界处叠出两条平行竖线。
*这里只用单层外边框 + 圆角,内部卡片靠各自的 padding 自然隔开,
*不画任何竖向分割线。子卡不应再自带边框/圆角/表面色。
*/
class BorderedRow extends StatelessWidget {
  const BorderedRow({required this.children, this.flexValues, super.key});

  final List<Widget> children;
  final List<int>? flexValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = theme.brightness == Brightness.light;
    return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.54 : 0.72), width: 1),
          boxShadow: [if (isLight) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++)
            Expanded(
              flex: (flexValues != null && i < flexValues!.length) ? flexValues![i] : 1,
              child: children[i],
            ),
        ]));
  }
}
