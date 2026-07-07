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

/* severity 索引:`0=info 1=success 2=warning 3=danger`, */
/* 与 `features/monitor/domain/entities.dart#AlertSeverity` 同序。 */
const int alertSeverityInfo = 0;
const int alertSeveritySuccess = 1;
const int alertSeverityWarning = 2;
const int alertSeverityDanger = 3;
