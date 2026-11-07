import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'ai_news_detail_tokens.dart';

/*
* 详情页的居中纵向滚动容器。
*/
class AiNewsDetailPageFrame extends StatelessWidget {
  const AiNewsDetailPageFrame({required this.child, required this.scrollKey, super.key});

  // 页面主体。
  final Widget child;

  // 用于测试并保存详情页滚动位置。
  final Key scrollKey;

  @override
  /* 构建按窗口宽度收敛边距的详情滚动区。 */
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? AppSpacing.lg : AppSpacing.xxl;
          return SingleChildScrollView(
            key: scrollKey,
            padding: EdgeInsets.fromLTRB(horizontal, AppSpacing.lg, horizontal, AppSpacing.xxl),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: aiNewsDetailMaxWidth),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
