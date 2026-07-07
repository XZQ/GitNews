import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/* 
*DevIntel 桌面端 home 演示数据(全部 const,便于后续替换为真实 API)。
*/
class DevIntelMetricSpec {
  const DevIntelMetricSpec({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
}

class DevIntelRepoRow {
  const DevIntelRepoRow({
    required this.rank,
    required this.name,
    required this.category,
    required this.lang,
    required this.newStars,
    required this.total,
    required this.color,
  });

  final String rank;
  final String name;
  final String category;
  final String lang;
  final String newStars;
  final String total;
  final Color color;
}

class DevIntelHotspot {
  const DevIntelHotspot({
    required this.abbr,
    required this.name,
    required this.tag,
    required this.color,
    required this.progress,
  });

  final String abbr;
  final String name;
  final String tag;
  final Color color;
  final double progress;
}

class DevIntelSignal {
  const DevIntelSignal({
    required this.title,
    required this.body,
    required this.dotColor,
  });

  final String title;
  final String body;
  final Color dotColor;
}

class DevIntelMonitoring {
  const DevIntelMonitoring({
    required this.name,
    required this.status,
    required this.statusColor,
    this.note,
  });

  final String name;
  final String status;
  final Color statusColor;
  final String? note;
}

const List<DevIntelMetricSpec> kDevIntelMetrics = <DevIntelMetricSpec>[
  DevIntelMetricSpec(
    title: '趋势仓库',
    value: '128',
    delta: '+18.7%',
    icon: Icons.show_chart_rounded,
    color: AppColors.info,
  ),
  DevIntelMetricSpec(
    title: '24h 新增 Star',
    value: '42.8K',
    delta: '+24.3%',
    icon: Icons.star_rounded,
    color: AppColors.warning,
  ),
  DevIntelMetricSpec(
    title: '活跃项目',
    value: '36',
    delta: '+5%',
    icon: Icons.rocket_launch_rounded,
    color: AppColors.brand,
  ),
  DevIntelMetricSpec(
    title: '已收藏仓库',
    value: '12',
    delta: '+2%',
    icon: Icons.bookmark_rounded,
    color: AppColors.accentPink,
  ),
];

const List<DevIntelRepoRow> kDevIntelRepoRows = <DevIntelRepoRow>[
  DevIntelRepoRow(
    rank: '01',
    name: 'shadcn-ui/ui',
    category: 'UI 库',
    lang: 'TypeScript',
    newStars: '+1,204',
    total: '84.2K',
    color: AppColors.info,
  ),
  DevIntelRepoRow(
    rank: '02',
    name: 'langchain-ai/langchain',
    category: 'AI 代理',
    lang: 'Python',
    newStars: '+892',
    total: '102K',
    color: AppColors.success,
  ),
  DevIntelRepoRow(
    rank: '03',
    name: 'tokio-rs/tokio',
    category: '系统',
    lang: 'Rust',
    newStars: '+456',
    total: '27.4K',
    color: AppColors.warning,
  ),
  DevIntelRepoRow(
    rank: '04',
    name: 'fabric/fabric.js',
    category: '画布',
    lang: 'TypeScript',
    newStars: '+234',
    total: '30.1K',
    color: AppColors.accentPurple,
  ),
];

const List<DevIntelHotspot> kDevIntelHotspots = <DevIntelHotspot>[
  DevIntelHotspot(
    abbr: 'AI',
    name: '生成式模型',
    tag: '热门',
    color: AppColors.success,
    progress: 0.92,
  ),
  DevIntelHotspot(
    abbr: 'RST',
    name: 'Rust 生态',
    tag: '稳健',
    color: AppColors.warning,
    progress: 0.68,
  ),
  DevIntelHotspot(
    abbr: 'WEB',
    name: '边缘计算',
    tag: '上升',
    color: AppColors.info,
    progress: 0.45,
  ),
  DevIntelHotspot(
    abbr: 'AGN',
    name: '代理框架',
    tag: '上升',
    color: AppColors.accentPurple,
    progress: 0.78,
  ),
];

const List<DevIntelSignal> kDevIntelSignals = <DevIntelSignal>[
  DevIntelSignal(
    title: 'Bun 1.0 运行时大规模迁移',
    body: '随着 Node.js 替代品获得关注,Bun 的采用率持续加速。',
    dotColor: AppColors.success,
  ),
  DevIntelSignal(
    title: 'npm/event-stream 潜在安全风险',
    body: '已发布低危公告 — 部署前请确认。',
    dotColor: AppColors.danger,
  ),
  DevIntelSignal(
    title: 'OpenAI DevDay 仓库激增',
    body: '多个热门仓库与 DevDay 发布及 SDK 更新相关。',
    dotColor: AppColors.info,
  ),
];

const List<DevIntelMonitoring> kDevIntelMonitoring = <DevIntelMonitoring>[
  DevIntelMonitoring(
    name: 'typescript-eslint',
    status: '同步中',
    statusColor: AppColors.info,
  ),
  DevIntelMonitoring(
    name: 'react-query',
    status: '稳定',
    statusColor: AppColors.success,
  ),
  DevIntelMonitoring(
    name: 'next.js',
    status: '高延迟',
    statusColor: AppColors.warning,
  ),
  DevIntelMonitoring(
    name: 'tailwindcss',
    status: '已排程',
    statusColor: AppColors.textMutedDark,
    note: '(12m)',
  ),
];

// X 轴标签(按数据点 index 取值),空字符串表示该点不显示。
const List<String> kDevIntelXLabels = <String>[
  '10/1',
  '',
  '10/8',
  '',
  '10/15',
  '',
  '10/22',
  '',
  '10/29',
  '',
  '',
  '',
  '今日',
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
