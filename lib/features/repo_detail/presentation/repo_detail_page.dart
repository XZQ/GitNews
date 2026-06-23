import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

class RepoDetailPage extends StatelessWidget {
  const RepoDetailPage({required this.fullName, super.key});

  final String fullName;

  @override
  Widget build(BuildContext context) {
    final repo = _lookupRepo();
    return Scaffold(
      appBar: AppBar(
        title: Text(repo.fullName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveLayout(
        compact: (_) => _Mobile(repo: repo),
        medium: (_) => CenteredContent(child: _Desktop(repo: repo)),
        expanded: (_) => CenteredContent(child: _Desktop(repo: repo)),
      ),
    );
  }

  DemoRepo _lookupRepo() {
    final all = [...DemoData.trending, ...DemoData.recent];
    return all.firstWhere(
      (r) => r.fullName == Uri.decodeComponent(fullName),
      orElse: () => DemoData.trending.first,
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.repo});
  final DemoRepo repo;

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
        _Header(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _Stats(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _Chart(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _Contributors(),
        const SizedBox(height: AppSpacing.lg),
        _Activity(),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        _Header(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: _Left(repo: repo)),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(flex: 4, child: _Right()),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(repo.color).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              repo.language.isNotEmpty ? repo.language[0] : '?',
              style: AppTypography.headlineLarge.copyWith(
                color: Color(repo.color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repo.fullName, style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                  repo.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Pill(text: repo.language, color: Color(repo.color)),
                    const _Pill(text: '公开仓库', color: AppColors.info),
                    const _Pill(text: '已加入监控', color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('监控'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border, size: 16),
                label: const Text('收藏'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '总 Star',
            value: _shortNumber(repo.starCount),
            icon: Icons.star_rounded,
            color: AppColors.starGold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: '今日新增',
            value: '+${_shortNumber(repo.starDelta)}',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Fork',
            value: _shortNumber(repo.forkCount),
            icon: Icons.call_split_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: '贡献者',
            value: '24',
            icon: Icons.people_outline,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Star 增长趋势',
                  subtitle: '最近 30 天 · 包含本仓库 + 同期均',
                ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7天')),
                  ButtonSegment(value: 30, label: Text('30天')),
                  ButtonSegment(value: 90, label: Text('90天')),
                ],
                selected: const {30},
                onSelectionChanged: (_) {},
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StarTrendChart(
            series: [
              ChartSeries(
                values: DemoData.generateStarTrend(repo.starCount - 5000, 5000),
                color: AppColors.brand,
              ),
              ChartSeries(
                values: DemoData.generateStarTrend(repo.starCount - 8000, 3500),
                color: AppColors.info,
              ),
            ],
            height: 220,
          ),
        ],
      ),
    );
  }
}

class _Contributors extends StatelessWidget {
  const _Contributors();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: '贡献者活跃度',
            subtitle: '本周贡献排行',
          ),
          SizedBox(height: AppSpacing.md),
          _ContribList(),
        ],
      ),
    );
  }
}

class _ContribList extends StatelessWidget {
  const _ContribList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in DemoData.contributors) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Color(c.avatarColor).withValues(alpha: 0.16),
              child: Text(
                c.login[0].toUpperCase(),
                style: AppTypography.titleSmall.copyWith(
                  color: Color(c.avatarColor),
                ),
              ),
            ),
            title: Text(c.login, style: AppTypography.titleSmall),
            subtitle: Text('+${c.contributions} 本周贡献'),
            trailing: const Icon(Icons.chevron_right, size: 18),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            title: '活动速览',
            subtitle: '近期 Commit / Issue / Release',
          ),
          SizedBox(height: AppSpacing.md),
          _ActivityList(),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        'feat: support streaming response',
        '4 小时前 · main',
        AppColors.success,
        Icons.commit
      ),
      (
        'fix: cache invalidation race',
        '6 小时前 · main',
        AppColors.info,
        Icons.bug_report_outlined
      ),
      (
        'chore: bump dependencies',
        '昨天 18:24 · main',
        AppColors.warning,
        Icons.upgrade
      ),
      ('release v0.42.1', '3 天前', AppColors.brand, Icons.local_fire_department),
    ];
    return Column(
      children: [
        for (final i in items) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: i.$3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(i.$4, color: i.$3, size: 18),
            ),
            title: Text(i.$1, style: AppTypography.titleSmall),
            subtitle: Text(i.$2, style: AppTypography.labelSmall),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _Left extends StatelessWidget {
  const _Left({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Stats(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _Chart(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _Contributors(),
        const SizedBox(height: AppSpacing.lg),
        _Activity(),
      ],
    );
  }
}

class _Right extends StatelessWidget {
  const _Right();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _AboutCard(),
        SizedBox(height: AppSpacing.lg),
        _TopicsCard(),
        SizedBox(height: AppSpacing.lg),
        _RelatedReposCard(),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: '关于', subtitle: 'README 摘要'),
          SizedBox(height: AppSpacing.md),
          Text(
            'A modern runtime for JavaScript and TypeScript. '
            'Built on V8, Rust, and Tokio. Provides a secure, '
            'production-ready environment for building web apps.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: '话题', subtitle: '仓库相关技术话题'),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('runtime')),
              Chip(label: Text('typescript')),
              Chip(label: Text('rust')),
              Chip(label: Text('cli')),
              Chip(label: Text('web')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedReposCard extends StatelessWidget {
  const _RelatedReposCard();

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
            child: SectionHeader(title: '相关仓库', subtitle: '同领域的热门项目'),
          ),
          for (final r in DemoData.trending.take(4)) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Color(r.color).withValues(alpha: 0.16),
                child: Text(
                  r.language[0],
                  style:
                      AppTypography.labelSmall.copyWith(color: Color(r.color)),
                ),
              ),
              title: Text(r.fullName, style: AppTypography.titleSmall),
              trailing: Text(
                '+${_shortNumber(r.starDelta)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}
