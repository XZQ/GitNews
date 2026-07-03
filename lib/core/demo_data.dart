/// 演示用静态数据(脚手架阶段,后续替换为 Repository 实现)。
///
/// 本文件只放 fixture,不允许业务模块直接 import 里面的类型;
/// 业务模块应 import 对应 domain 实体,由 data 层调用 [DemoDataMappers] 完成映射。
library;

class DemoRepoFixture {
  const DemoRepoFixture({
    required this.fullName,
    required this.description,
    required this.language,
    required this.starCount,
    required this.starDelta,
    required this.forkCount,
    required this.color,
    this.trend,
  });

  final String fullName;
  final String description;
  final String language;
  final int starCount;
  final int starDelta;
  final int forkCount;
  final int color;
  final List<double>? trend;
}

class DemoAlertFixture {
  const DemoAlertFixture({
    required this.repo,
    required this.metric,
    required this.value,
    required this.time,
    required this.severity,
  });

  final String repo;
  final String metric;
  final String value;
  final String time;
  final int severity;
}

class DemoLanguageFixture {
  const DemoLanguageFixture({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
  });

  final String name;
  final double percent;
  final double delta;
  final int color;
}

class DemoContributorFixture {
  const DemoContributorFixture({
    required this.login,
    required this.contributions,
    required this.avatarColor,
  });

  final String login;
  final int contributions;
  final int avatarColor;
}

/// severity 索引:`0=info 1=success 2=warning 3=danger`,
/// 与 `features/monitor/domain/entities.dart#AlertSeverity` 同序。
const int alertSeverityInfo = 0;
const int alertSeveritySuccess = 1;
const int alertSeverityWarning = 2;
const int alertSeverityDanger = 3;

class DemoData {
  const DemoData._();

  static const List<DemoRepoFixture> trending = [
    DemoRepoFixture(
      fullName: 'openai/whisper',
      description: 'Robust Speech Recognition via Large-Scale Weak Supervision',
      language: 'Python',
      starCount: 72341,
      starDelta: 1280,
      forkCount: 8120,
      color: 0xFF3572A5,
    ),
    DemoRepoFixture(
      fullName: 'ggerganov/llama.cpp',
      description: 'LLM inference in C/C++',
      language: 'C++',
      starCount: 64120,
      starDelta: 964,
      forkCount: 8930,
      color: 0xFFDEA584,
    ),
    DemoRepoFixture(
      fullName: 'openai/openai-python',
      description: 'The official Python library for the OpenAI API',
      language: 'Python',
      starCount: 21430,
      starDelta: 421,
      forkCount: 3120,
      color: 0xFF3572A5,
    ),
    DemoRepoFixture(
      fullName: 'anthropics/claude-code',
      description: 'Anthropic’s official CLI for Claude',
      language: 'TypeScript',
      starCount: 18020,
      starDelta: 612,
      forkCount: 1240,
      color: 0xFF3178C6,
    ),
    DemoRepoFixture(
      fullName: 'denoland/deno',
      description: 'A modern runtime for JavaScript and TypeScript',
      language: 'Rust',
      starCount: 94210,
      starDelta: 312,
      forkCount: 5230,
      color: 0xFFDEA584,
    ),
    DemoRepoFixture(
      fullName: 'withastro/astro',
      description: 'The web framework for content-driven websites',
      language: 'TypeScript',
      starCount: 45330,
      starDelta: 188,
      forkCount: 2340,
      color: 0xFF3178C6,
    ),
    DemoRepoFixture(
      fullName: 'ggerganov/whisper.cpp',
      description: 'Port of OpenAI’s Whisper model in C/C++',
      language: 'C++',
      starCount: 32480,
      starDelta: 244,
      forkCount: 3210,
      color: 0xFFDEA584,
    ),
    DemoRepoFixture(
      fullName: 'lapce/lapce',
      description: 'Lightning-fast and Powerful Code Editor',
      language: 'Rust',
      starCount: 35120,
      starDelta: 156,
      forkCount: 1120,
      color: 0xFFDEA584,
    ),
  ];

  static const List<DemoRepoFixture> recent = [
    DemoRepoFixture(
      fullName: 'mrdoob/three.js',
      description: 'JavaScript 3D Library',
      language: 'JavaScript',
      starCount: 102100,
      starDelta: 102,
      forkCount: 35620,
      color: 0xFFF1E05A,
    ),
    DemoRepoFixture(
      fullName: 'vitejs/vite',
      description: 'Next generation frontend tooling',
      language: 'TypeScript',
      starCount: 68120,
      starDelta: 86,
      forkCount: 6210,
      color: 0xFF3178C6,
    ),
    DemoRepoFixture(
      fullName: 'tauri-apps/tauri',
      description: 'Build smaller, faster, more secure desktops',
      language: 'Rust',
      starCount: 82340,
      starDelta: 64,
      forkCount: 2410,
      color: 0xFFDEA584,
    ),
  ];

  static const List<DemoAlertFixture> alerts = [
    DemoAlertFixture(
      repo: 'openai/whisper',
      metric: '今日新增 Star',
      value: '+1,280',
      time: '2 分钟前',
      severity: alertSeveritySuccess,
    ),
    DemoAlertFixture(
      repo: 'anthropics/claude-code',
      metric: '单日 Star 增长',
      value: '+18.5%',
      time: '12 分钟前',
      severity: alertSeveritySuccess,
    ),
    DemoAlertFixture(
      repo: 'denoland/deno',
      metric: '监控告警 · Star 增速回落',
      value: '-2.1%',
      time: '28 分钟前',
      severity: alertSeverityWarning,
    ),
    DemoAlertFixture(
      repo: 'mrdoob/three.js',
      metric: '讨论热度上升',
      value: '+322%',
      time: '1 小时前',
      severity: alertSeverityInfo,
    ),
    DemoAlertFixture(
      repo: 'lapce/lapce',
      metric: '监控告警 · 阈值触发',
      value: '> 200/天',
      time: '2 小时前',
      severity: alertSeverityDanger,
    ),
  ];

  static const List<DemoLanguageFixture> languages = [
    DemoLanguageFixture(
      name: 'TypeScript',
      percent: 28.5,
      delta: 18.7,
      color: 0xFF3178C6,
    ),
    DemoLanguageFixture(
      name: 'Python',
      percent: 22.1,
      delta: 12.3,
      color: 0xFF3572A5,
    ),
    DemoLanguageFixture(
      name: 'Rust',
      percent: 14.8,
      delta: 9.8,
      color: 0xFFDEA584,
    ),
    DemoLanguageFixture(
      name: 'Go',
      percent: 9.2,
      delta: 4.2,
      color: 0xFF00ADD8,
    ),
    DemoLanguageFixture(
      name: 'Java',
      percent: 7.1,
      delta: 1.5,
      color: 0xFFB07219,
    ),
    DemoLanguageFixture(
      name: 'C++',
      percent: 5.6,
      delta: 2.8,
      color: 0xFFDEA584,
    ),
    DemoLanguageFixture(
      name: 'Swift',
      percent: 3.8,
      delta: 6.4,
      color: 0xFFFA7343,
    ),
    DemoLanguageFixture(
      name: 'Kotlin',
      percent: 2.9,
      delta: 1.1,
      color: 0xFFA97BFF,
    ),
    DemoLanguageFixture(
      name: 'Other',
      percent: 6.0,
      delta: 0.4,
      color: 0xFF9CA0AC,
    ),
  ];

  static const List<DemoContributorFixture> contributors = [
    DemoContributorFixture(
      login: 'ggerganov',
      contributions: 1284,
      avatarColor: 0xFF0D9488,
    ),
    DemoContributorFixture(
      login: 'sama',
      contributions: 982,
      avatarColor: 0xFFE5A150,
    ),
    DemoContributorFixture(
      login: 'yyx990803',
      contributions: 712,
      avatarColor: 0xFF30A46C,
    ),
    DemoContributorFixture(
      login: 'tj',
      contributions: 645,
      avatarColor: 0xFFE5464D,
    ),
    DemoContributorFixture(
      login: 'yyx990803',
      contributions: 521,
      avatarColor: 0xFF4CB5FF,
    ),
  ];

  /// Star 趋势生成(演示)。[count] 控制点数。
  static List<double> generateStarTrend(int base, int delta, {int count = 30}) {
    final last = count - 1;
    return List<double>.generate(count, (i) {
      final progress = last == 0 ? 0.0 : i / last;
      final noise = ((i * 13) % 7) - 3;
      return (base + delta * progress + noise).toDouble();
    });
  }
}
