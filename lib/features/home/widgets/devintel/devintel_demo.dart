import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// DevIntel 桌面端 home 演示数据(全部 const,便于后续替换为真实 API)。
///
/// 注:`title` / `name` / `tag` / `statusLabel` / `body` / 列名 / X 轴标签
/// 等是 i18n key,UI 渲染时通过 `context.t.t(key)` 解析。
class DevIntelMetricSpec {
  const DevIntelMetricSpec({
    required this.titleKey,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String titleKey;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
}

class DevIntelRepoRow {
  const DevIntelRepoRow({
    required this.rank,
    required this.name,
    required this.categoryKey,
    required this.lang,
    required this.newStars,
    required this.total,
    required this.color,
  });

  final String rank;
  final String name;
  final String categoryKey;
  final String lang;
  final String newStars;
  final String total;
  final Color color;
}

class DevIntelHotspot {
  const DevIntelHotspot({
    required this.abbr,
    required this.nameKey,
    required this.tagKey,
    required this.color,
    required this.progress,
  });

  final String abbr;
  final String nameKey;
  final String tagKey;
  final Color color;
  final double progress;
}

class DevIntelSignal {
  const DevIntelSignal({
    required this.titleKey,
    required this.bodyKey,
    required this.dotColor,
  });

  final String titleKey;
  final String bodyKey;
  final Color dotColor;
}

class DevIntelMonitoring {
  const DevIntelMonitoring({
    required this.name,
    required this.statusKey,
    required this.statusColor,
    this.note,
  });

  final String name;
  final String statusKey;
  final Color statusColor;
  final String? note;
}

const List<DevIntelMetricSpec> kDevIntelMetrics = <DevIntelMetricSpec>[
  DevIntelMetricSpec(
    titleKey: 'devintel.metric.trendingRepos',
    value: '128',
    delta: '+18.7%',
    icon: Icons.show_chart_rounded,
    color: AppColors.info,
  ),
  DevIntelMetricSpec(
    titleKey: 'devintel.metric.newStars24h',
    value: '42.8K',
    delta: '+24.3%',
    icon: Icons.star_rounded,
    color: AppColors.warning,
  ),
  DevIntelMetricSpec(
    titleKey: 'devintel.metric.activeProjects',
    value: '36',
    delta: '+5%',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFF8B73E5),
  ),
  DevIntelMetricSpec(
    titleKey: 'devintel.metric.starredRepos',
    value: '12',
    delta: '+2%',
    icon: Icons.bookmark_rounded,
    color: Color(0xFFEC4899),
  ),
];

const List<DevIntelRepoRow> kDevIntelRepoRows = <DevIntelRepoRow>[
  DevIntelRepoRow(
    rank: '01',
    name: 'shadcn-ui/ui',
    categoryKey: 'devintel.cat.uiLibrary',
    lang: 'TypeScript',
    newStars: '+1,204',
    total: '84.2K',
    color: AppColors.info,
  ),
  DevIntelRepoRow(
    rank: '02',
    name: 'langchain-ai/langchain',
    categoryKey: 'devintel.cat.aiAgent',
    lang: 'Python',
    newStars: '+892',
    total: '102K',
    color: AppColors.success,
  ),
  DevIntelRepoRow(
    rank: '03',
    name: 'tokio-rs/tokio',
    categoryKey: 'devintel.cat.systems',
    lang: 'Rust',
    newStars: '+456',
    total: '27.4K',
    color: AppColors.warning,
  ),
  DevIntelRepoRow(
    rank: '04',
    name: 'fabric/fabric.js',
    categoryKey: 'devintel.cat.canvas',
    lang: 'TypeScript',
    newStars: '+234',
    total: '30.1K',
    color: Color(0xFFA78BFA),
  ),
];

const List<DevIntelHotspot> kDevIntelHotspots = <DevIntelHotspot>[
  DevIntelHotspot(
    abbr: 'AI',
    nameKey: 'devintel.hot.ai.name',
    tagKey: 'devintel.hot.ai.tag',
    color: AppColors.success,
    progress: 0.92,
  ),
  DevIntelHotspot(
    abbr: 'RST',
    nameKey: 'devintel.hot.rust.name',
    tagKey: 'devintel.hot.stable.tag',
    color: AppColors.warning,
    progress: 0.68,
  ),
  DevIntelHotspot(
    abbr: 'WEB',
    nameKey: 'devintel.hot.web.name',
    tagKey: 'devintel.hot.trending.tag',
    color: AppColors.info,
    progress: 0.45,
  ),
  DevIntelHotspot(
    abbr: 'AGN',
    nameKey: 'devintel.hot.agent.name',
    tagKey: 'devintel.hot.trending.tag',
    color: Color(0xFFA78BFA),
    progress: 0.78,
  ),
];

const List<DevIntelSignal> kDevIntelSignals = <DevIntelSignal>[
  DevIntelSignal(
    titleKey: 'devintel.signal.1.title',
    bodyKey: 'devintel.signal.1.body',
    dotColor: AppColors.success,
  ),
  DevIntelSignal(
    titleKey: 'devintel.signal.2.title',
    bodyKey: 'devintel.signal.2.body',
    dotColor: AppColors.danger,
  ),
  DevIntelSignal(
    titleKey: 'devintel.signal.3.title',
    bodyKey: 'devintel.signal.3.body',
    dotColor: AppColors.info,
  ),
];

const List<DevIntelMonitoring> kDevIntelMonitoring = <DevIntelMonitoring>[
  DevIntelMonitoring(
    name: 'typescript-eslint',
    statusKey: 'devintel.status.syncing',
    statusColor: AppColors.info,
  ),
  DevIntelMonitoring(
    name: 'react-query',
    statusKey: 'devintel.status.stable',
    statusColor: AppColors.success,
  ),
  DevIntelMonitoring(
    name: 'next.js',
    statusKey: 'devintel.status.highLatency',
    statusColor: AppColors.warning,
  ),
  DevIntelMonitoring(
    name: 'tailwindcss',
    statusKey: 'devintel.status.scheduled',
    statusColor: Color(0xFF71717A),
    note: '(12m)',
  ),
];

/// X 轴标签(按数据点 index 取值),通过 i18n 解析。
const List<String> kDevIntelXLabels = <String>[
  'devintel.chart.month1',
  '',
  'devintel.chart.month8',
  '',
  'devintel.chart.month15',
  '',
  'devintel.chart.month22',
  '',
  'devintel.chart.month29',
  '',
  '',
  '',
  'devintel.chart.today',
];

const List<double> kDevIntelChartValues7 = <double>[
  43200,
  43850,
  44100,
  44620,
  45210,
  46120,
  47830,
];

const List<double> kDevIntelChartValues30 = <double>[
  38200,
  38800,
  38420,
  39120,
  39840,
  40120,
  40850,
  41200,
  41620,
  42120,
  41850,
  42210,
  42580,
  43120,
  43850,
  44100,
  44620,
  45210,
  46120,
  47000,
  46850,
  47200,
  46500,
  46920,
  47100,
  46800,
  47250,
  47600,
  48000,
  49600,
];
