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

class DemoLanguageFixture {
  const DemoLanguageFixture({required this.name, required this.percent, required this.delta, required this.color});

  final String name;
  final double percent;
  final double delta;
  final int color;
}

class DemoContributorFixture {
  const DemoContributorFixture({required this.login, required this.contributions, required this.avatarColor});

  final String login;
  final int contributions;
  final int avatarColor;
}
