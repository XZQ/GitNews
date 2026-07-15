import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/breakpoint.dart';

/* 
*通用响应式布局工具。
*/
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({required this.compact, required this.medium, required this.expanded, super.key});

  final WidgetBuilder compact;
  final WidgetBuilder medium;
  final WidgetBuilder expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final formFactor = Breakpoints.of(context);
      return switch (formFactor) { FormFactor.compact => compact(context), FormFactor.medium => medium(context), FormFactor.expanded => expanded(context) };
    });
  }
}

/* 
*居中并限制最大宽度的容器(在 Expanded/Medium 形态下让内容不要拉满全宽)。
*/
class CenteredContent extends StatelessWidget {
  const CenteredContent({required this.child, this.maxWidth = 1680, this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg), super.key});

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: Padding(padding: padding, child: child)));
  }
}
