/// 演示用静态数据(脚手架阶段,后续替换为 Repository)。
library;

class DemoRepo {
  const DemoRepo({
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

class DemoAlert {
  const DemoAlert({
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
  final AlertSeverity severity;
}

enum AlertSeverity { info, success, warning, danger }

class DemoLanguage {
  const DemoLanguage({
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

class DemoContributor {
  const DemoContributor({
    required this.login,
    required this.contributions,
    required this.avatarColor,
  });

  final String login;
  final int contributions;
  final int avatarColor;
}

class DemoData {
  const DemoData._();

  static const List<DemoRepo> trending = [
    DemoRepo(
      fullName: 'openai/whisper',
      description: 'Robust Speech Recognition via Large-Scale Weak Supervision',
      language: 'Python',
      starCount: 72341,
      starDelta: 1280,
      forkCount: 8120,
      color: 0xFF3572A5,
    ),
    DemoRepo(
      fullName: 'ggerganov/llama.cpp',
      description: 'LLM inference in C/C++',
      language: 'C++',
      starCount: 64120,
      starDelta: 964,
      forkCount: 8930,
      color: 0xFFDEA584,
    ),
    DemoRepo(
      fullName: 'openai/openai-python',
      description: 'The official Python library for the OpenAI API',
      language: 'Python',
      starCount: 21430,
      starDelta: 421,
      forkCount: 3120,
      color: 0xFF3572A5,
    ),
    DemoRepo(
      fullName: 'anthropics/claude-code',
      description: 'Anthropic’s official CLI for Claude',
      language: 'TypeScript',
      starCount: 18020,
      starDelta: 612,
      forkCount: 1240,
      color: 0xFF3178C6,
    ),
    DemoRepo(
      fullName: 'denoland/deno',
      description: 'A modern runtime for JavaScript and TypeScript',
      language: 'Rust',
      starCount: 94210,
      starDelta: 312,
      forkCount: 5230,
      color: 0xFFDEA584,
    ),
    DemoRepo(
      fullName: 'withastro/astro',
      description: 'The web framework for content-driven websites',
      language: 'TypeScript',
      starCount: 45330,
      starDelta: 188,
      forkCount: 2340,
      color: 0xFF3178C6,
    ),
    DemoRepo(
      fullName: 'ggerganov/whisper.cpp',
      description: 'Port of OpenAI’s Whisper model in C/C++',
      language: 'C++',
      starCount: 32480,
      starDelta: 244,
      forkCount: 3210,
      color: 0xFFDEA584,
    ),
    DemoRepo(
      fullName: 'lapce/lapce',
      description: 'Lightning-fast and Powerful Code Editor',
      language: 'Rust',
      starCount: 35120,
      starDelta: 156,
      forkCount: 1120,
      color: 0xFFDEA584,
    ),
  ];

  static const List<DemoRepo> recent = [
    DemoRepo(
      fullName: 'mrdoob/three.js',
      description: 'JavaScript 3D Library',
      language: 'JavaScript',
      starCount: 102100,
      starDelta: 102,
      forkCount: 35620,
      color: 0xFFF1E05A,
    ),
    DemoRepo(
      fullName: 'vitejs/vite',
      description: 'Next generation frontend tooling',
      language: 'TypeScript',
      starCount: 68120,
      starDelta: 86,
      forkCount: 6210,
      color: 0xFF3178C6,
    ),
    DemoRepo(
      fullName: 'tauri-apps/tauri',
      description: 'Build smaller, faster, more secure desktops',
      language: 'Rust',
      starCount: 82340,
      starDelta: 64,
      forkCount: 2410,
      color: 0xFFDEA584,
    ),
  ];

  static const List<DemoAlert> alerts = [
    DemoAlert(
      repo: 'openai/whisper',
      metric: 'New stars today',
      value: '+1,280',
      time: '2 min ago',
      severity: AlertSeverity.success,
    ),
    DemoAlert(
      repo: 'anthropics/claude-code',
      metric: 'Daily Star growth',
      value: '+18.5%',
      time: '12 min ago',
      severity: AlertSeverity.success,
    ),
    DemoAlert(
      repo: 'denoland/deno',
      metric: 'Alert · Star velocity drop',
      value: '-2.1%',
      time: '28 min ago',
      severity: AlertSeverity.warning,
    ),
    DemoAlert(
      repo: 'mrdoob/three.js',
      metric: 'Discussion heat rising',
      value: '+322%',
      time: '1 hour ago',
      severity: AlertSeverity.info,
    ),
    DemoAlert(
      repo: 'lapce/lapce',
      metric: 'Alert · threshold triggered',
      value: '> 200/天',
      time: '2 hours ago',
      severity: AlertSeverity.danger,
    ),
  ];

  static const List<DemoLanguage> languages = [
    DemoLanguage(
      name: 'TypeScript',
      percent: 28.5,
      delta: 18.7,
      color: 0xFF3178C6,
    ),
    DemoLanguage(name: 'Python', percent: 22.1, delta: 12.3, color: 0xFF3572A5),
    DemoLanguage(name: 'Rust', percent: 14.8, delta: 9.8, color: 0xFFDEA584),
    DemoLanguage(name: 'Go', percent: 9.2, delta: 4.2, color: 0xFF00ADD8),
    DemoLanguage(name: 'Java', percent: 7.1, delta: 1.5, color: 0xFFB07219),
    DemoLanguage(name: 'C++', percent: 5.6, delta: 2.8, color: 0xFFDEA584),
    DemoLanguage(name: 'Swift', percent: 3.8, delta: 6.4, color: 0xFFFA7343),
    DemoLanguage(name: 'Kotlin', percent: 2.9, delta: 1.1, color: 0xFFA97BFF),
    DemoLanguage(name: 'Other', percent: 6.0, delta: 0.4, color: 0xFF9CA0AC),
  ];

  static const List<DemoContributor> contributors = [
    DemoContributor(
        login: 'ggerganov', contributions: 1284, avatarColor: 0xFF6E56CF),
    DemoContributor(login: 'sama', contributions: 982, avatarColor: 0xFFE5A150),
    DemoContributor(
        login: 'yyx990803', contributions: 712, avatarColor: 0xFF30A46C),
    DemoContributor(login: 'tj', contributions: 645, avatarColor: 0xFFE5464D),
    DemoContributor(
        login: 'yyx990803', contributions: 521, avatarColor: 0xFF4CB5FF),
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
