import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/ai_news_item.dart';
import 'ai_news_detail_extended.dart';
import 'ai_news_detail_insights.dart';
import 'ai_news_detail_overview.dart';

/*
*AI 资讯详情的三页横向阅读流。
*
*每页拥有独立纵向滚动位置;触摸、鼠标拖动和触控板都可横向翻页。
*/
class AiNewsDetailContent extends StatefulWidget {
  const AiNewsDetailContent({
    required this.item,
    this.relatedItems = const [],
    this.showEnrichment = true,
    this.initialPage = 0,
    this.onOpenOriginal,
    this.onOpenRelated,
    this.onViewMore,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 本地相关推荐。
  final List<AiNewsItem> relatedItems;

  // 是否读取本地 AI 增强状态。
  final bool showEnrichment;

  // 初始页,用于恢复和视觉测试。
  final int initialPage;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  // 打开相关推荐操作。
  final ValueChanged<AiNewsItem>? onOpenRelated;

  // 返回资讯列表操作。
  final VoidCallback? onViewMore;

  @override
  /* 创建横向分页控制器状态。 */
  State<AiNewsDetailContent> createState() => _AiNewsDetailContentState();
}

/*
*维护详情阅读流的页面控制器。
*/
class _AiNewsDetailContentState extends State<AiNewsDetailContent> {
  // 横向三页控制器。
  late final PageController _pageController;

  @override
  /* 按指定初始页创建控制器。 */
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialPage.clamp(0, 2).toInt(),
    );
  }

  @override
  /* 释放分页控制器。 */
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  /* 构建三页可横向拖动的详情内容。 */
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _AiNewsDetailScrollBehavior(),
      child: PageView(
        key: const ValueKey('ai-news-detail-pages'),
        controller: _pageController,
        allowImplicitScrolling: true,
        children: [
          AiNewsDetailOverview(
            item: widget.item,
            onOpenOriginal: widget.onOpenOriginal,
          ),
          AiNewsDetailInsights(
            item: widget.item,
            showEnrichment: widget.showEnrichment,
            onOpenOriginal: widget.onOpenOriginal,
          ),
          AiNewsDetailExtended(
            item: widget.item,
            relatedItems: widget.relatedItems,
            onOpenOriginal: widget.onOpenOriginal,
            onOpenRelated: widget.onOpenRelated,
            onViewMore: widget.onViewMore,
          ),
        ],
      ),
    );
  }
}

/*
*让桌面鼠标拖动与触控设备都可翻页的滚动策略。
*/
class _AiNewsDetailScrollBehavior extends MaterialScrollBehavior {
  const _AiNewsDetailScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
