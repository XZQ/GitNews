import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// DevIntel 桌面端 home 演示数据(全部 const,便于后续替换为真实 API)。
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
    required this.statusLabel,
    required this.statusColor,
    this.note,
  });

  final String name;
  final String statusLabel;
  final Color statusColor;
  final String? note;
}

const List<DevIntelMetricSpec> kDevIntelMetrics = <DevIntelMetricSpec>[
  DevIntelMetricSpec(
    title: 'Trending Repos',
    value: '128',
    delta: '+18.7%',
    icon: Icons.show_chart_rounded,
    color: AppColors.info,
  ),
  DevIntelMetricSpec(
    title: 'New Stars (24h)',
    value: '42.8K',
    delta: '+24.3%',
    icon: Icons.star_rounded,
    color: AppColors.warning,
  ),
  DevIntelMetricSpec(
    title: 'Active Projects',
    value: '36',
    delta: '+5%',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFF8B73E5),
  ),
  DevIntelMetricSpec(
    title: 'Starred Repos',
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
    category: 'UI LIBRARY',
    lang: 'TypeScript',
    newStars: '+1,204',
    total: '84.2K',
    color: AppColors.info,
  ),
  DevIntelRepoRow(
    rank: '02',
    name: 'langchain-ai/langchain',
    category: 'AI AGENT',
    lang: 'Python',
    newStars: '+892',
    total: '102K',
    color: AppColors.success,
  ),
  DevIntelRepoRow(
    rank: '03',
    name: 'tokio-rs/tokio',
    category: 'SYSTEMS',
    lang: 'Rust',
    newStars: '+456',
    total: '27.4K',
    color: AppColors.warning,
  ),
  DevIntelRepoRow(
    rank: '04',
    name: 'fabric/fabric.js',
    category: 'CANVAS',
    lang: 'TypeScript',
    newStars: '+234',
    total: '30.1K',
    color: Color(0xFFA78BFA),
  ),
];

const List<DevIntelHotspot> kDevIntelHotspots = <DevIntelHotspot>[
  DevIntelHotspot(
    abbr: 'AI',
    name: 'Generative Models',
    tag: 'HOT',
    color: AppColors.success,
    progress: 0.92,
  ),
  DevIntelHotspot(
    abbr: 'RST',
    name: 'Rust Ecosystem',
    tag: 'STABLE',
    color: AppColors.warning,
    progress: 0.68,
  ),
  DevIntelHotspot(
    abbr: 'WEB',
    name: 'Edge Computing',
    tag: 'TRENDING',
    color: AppColors.info,
    progress: 0.45,
  ),
  DevIntelHotspot(
    abbr: 'AGN',
    name: 'Agent Frameworks',
    tag: 'TRENDING',
    color: Color(0xFFA78BFA),
    progress: 0.78,
  ),
];

const List<DevIntelSignal> kDevIntelSignals = <DevIntelSignal>[
  DevIntelSignal(
    title: 'Massive migration detected to Bun 1.0 runtime',
    body:
        'Bun adoption accelerates as Node.js alternatives gain traction across the ecosystem.',
    dotColor: AppColors.success,
  ),
  DevIntelSignal(
    title: 'Potential security vulnerability in npm/event-stream',
    body: 'Low severity advisory published — review before next deploy.',
    dotColor: AppColors.danger,
  ),
  DevIntelSignal(
    title: 'OpenAI DevDay repositories surging',
    body:
        'Multiple trending repos correlate with DevDay announcements and SDK releases.',
    dotColor: AppColors.info,
  ),
];

const List<DevIntelMonitoring> kDevIntelMonitoring = <DevIntelMonitoring>[
  DevIntelMonitoring(
    name: 'typescript-eslint',
    statusLabel: 'Syncing',
    statusColor: AppColors.info,
  ),
  DevIntelMonitoring(
    name: 'react-query',
    statusLabel: 'Stable',
    statusColor: AppColors.success,
  ),
  DevIntelMonitoring(
    name: 'next.js',
    statusLabel: 'High Latency',
    statusColor: AppColors.warning,
  ),
  DevIntelMonitoring(
    name: 'tailwindcss',
    statusLabel: 'Scheduled',
    statusColor: Color(0xFF71717A),
    note: '(12m)',
  ),
];

const List<String> kDevIntelXLabels = <String>[
  'OCT 1',
  '',
  'OCT 8',
  '',
  'OCT 15',
  '',
  'OCT 22',
  '',
  'OCT 29',
  '',
  '',
  '',
  'TODAY',
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
