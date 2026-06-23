import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('趋势')),
      body: ResponsiveLayout(
        compact: (_) => const _TrendingMobile(),
        medium: (_) => const _TrendingDesktop(),
        expanded: (_) => const _TrendingDesktop(),
      ),
    );
  }
}

/// 手机:时间窗 / 筛选 + Hero 趋势图 + 列表 + 趋势主题。
class _TrendingMobile extends StatefulWidget {
  const _TrendingMobile();

  @override
  State<_TrendingMobile> createState() => _TrendingMobileState();
}

class _TrendingMobileState extends State<_TrendingMobile> {
  String _window = '今日';
  String _lang = '全部语言';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        // 趋势设计稿 hero
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Star 增长榜',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  _PopupMenu(
                    value: _lang,
                    options: const ['全部语言', 'TypeScript', 'Python', 'Rust'],
                    onSelected: (v) => setState(() => _lang = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '追踪 $_window · Star 增速排名',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _WindowSegmented(
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const _HeroMetrics(),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: DemoData.generateStarTrend(40000, 3200),
                    color: AppColors.brand,
                  ),
                  ChartSeries(
                    values: DemoData.generateStarTrend(42000, 3500),
                    color: AppColors.success,
                  ),
                ],
                height: 200,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '热门仓库',
                  subtitle: '$_window · ${DemoData.trending.length} 个项目',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('筛选'),
                  ),
                ),
              ),
              for (var i = 0; i < DemoData.trending.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: DemoData.trending[i],
                  onTap: () => context.go(
                    '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _TopicsPanel(),
      ],
    );
  }
}

/// 桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
class _TrendingDesktop extends StatefulWidget {
  const _TrendingDesktop();

  @override
  State<_TrendingDesktop> createState() => _TrendingDesktopState();
}

class _TrendingDesktopState extends State<_TrendingDesktop> {
  String _lang = 'All';

  @override
  Widget build(BuildContext context) {
    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Star 增长趋势',
                  subtitle: '追踪时间窗内的新增 Star 总量 · 包含所有语言',
                ),
                const SizedBox(height: AppSpacing.md),
                StarTrendChart(
                  series: [
                    ChartSeries(
                      values: DemoData.generateStarTrend(38000, 4200),
                      color: AppColors.brand,
                    ),
                    ChartSeries(
                      values: DemoData.generateStarTrend(35200, 3100),
                      color: AppColors.info,
                    ),
                    ChartSeries(
                      values: DemoData.generateStarTrend(32000, 2800),
                      color: AppColors.success,
                    ),
                  ],
                  height: 280,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 8, child: _TrendingList()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _LanguagePanel(
                        value: _lang,
                        onChanged: (v) => setState(() => _lang = v)),
                    const SizedBox(height: AppSpacing.lg),
                    const _TopicsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '热门仓库',
              subtitle: '按 Star 增速排序',
            ),
          ),
          for (var i = 0; i < DemoData.trending.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: DemoData.trending[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WindowSegmented extends StatelessWidget {
  const _WindowSegmented({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '今日', label: Text('今日')),
        ButtonSegment(value: '本周', label: Text('本周')),
        ButtonSegment(value: '本月', label: Text('本月')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _PopupMenu extends StatelessWidget {
  const _PopupMenu({
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: 14),
            const SizedBox(width: 4),
            Text(value, style: AppTypography.labelMedium),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  const _HeroMetrics();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _Metric(value: '42.8K', label: 'Star 增长总量', delta: '+7.2%'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _Metric(value: '1.20K', label: '周活跃仓库', delta: '+12.4%'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _Metric(value: '10.6K', label: '新增 Fork', delta: '+5.1%'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _Metric(value: '623', label: '热门话题', delta: '+3.4%'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.delta,
  });

  final String value;
  final String label;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.headlineMedium),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          delta,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _categoryMap = <String, List<String>>{
    'AI': ['Python', 'TypeScript', 'Rust'],
    'Web': ['TypeScript', 'Java', 'Kotlin', 'Swift'],
    'System': ['Rust', 'C++', 'Go'],
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _filterLanguages(value);
    final subtitle = _subtitleFor(value, filtered.length);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '语言分布',
            subtitle: subtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('全部')),
              ButtonSegment(value: 'AI', label: Text('AI')),
              ButtonSegment(value: 'Web', label: Text('Web')),
              ButtonSegment(value: 'System', label: Text('系统')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                '该分类暂无数据',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final l in filtered) ...[
              _LangRow(
                name: l.name,
                percent: l.percent,
                delta: l.delta,
                color: Color(l.color),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  List<DemoLanguage> _filterLanguages(String category) {
    if (category == 'All' || !_categoryMap.containsKey(category)) {
      return DemoData.languages.take(7).toList();
    }
    final names = _categoryMap[category]!.toSet();
    return DemoData.languages.where((l) => names.contains(l.name)).toList();
  }

  String _subtitleFor(String category, int count) {
    switch (category) {
      case 'AI':
        return 'AI / ML 方向 · $count 种语言';
      case 'Web':
        return 'Web 与前端 · $count 种语言';
      case 'System':
        return '系统与基础设施 · $count 种语言';
      case 'All':
      default:
        return '热门仓库的编程语言占比 · 共 $count 种';
    }
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
  });

  final String name;
  final double percent;
  final double delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: AppTypography.titleSmall,
          ),
        ),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(width: 8),
        Text(
          '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
          style: AppTypography.labelSmall.copyWith(
            color: delta >= 0 ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TopicsPanel extends StatelessWidget {
  const _TopicsPanel();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: '话题趋势',
            subtitle: '本周高频出现的技术话题',
          ),
          SizedBox(height: AppSpacing.md),
          _TopicWordCloud(),
        ],
      ),
    );
  }
}

class _TopicWordCloud extends StatelessWidget {
  const _TopicWordCloud();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: const [
        _TopicWord(text: 'AI Agent', size: 22, weight: 0.9),
        _TopicWord(text: 'DevTools', size: 20, weight: 0.85),
        _TopicWord(text: 'RAG', size: 16, weight: 0.6),
        _TopicWord(text: 'LLM', size: 18, weight: 0.7),
        _TopicWord(text: 'Web3', size: 17, weight: 0.65),
        _TopicWord(text: 'Cloud Native', size: 14, weight: 0.5),
        _TopicWord(text: 'Data Infra', size: 13, weight: 0.45),
        _TopicWord(text: 'Security', size: 15, weight: 0.55),
      ],
    );
  }
}

class _TopicWord extends StatelessWidget {
  const _TopicWord(
      {required this.text, required this.size, required this.weight});
  final String text;
  final double size;
  final double weight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lightness = 0.45 + weight * 0.4;
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: HSLColor.fromColor(colors.primary)
            .withLightness(lightness.clamp(0.3, 0.7))
            .toColor(),
      ),
    );
  }
}
