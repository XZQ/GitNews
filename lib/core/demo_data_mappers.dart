import '../features/monitor/domain/entities.dart';
import '../features/repo_detail/domain/entities.dart';
import 'demo_data.dart';
import 'domain/repo_entity.dart';

/* Demo fixture → domain 实体的映射集合。 */
/*  */
/* 仅在 data 层(LocalXxxRepository)使用,domain 不允许依赖本文件。 */
extension DemoRepoFixtureX on DemoRepoFixture {
  RepoEntity toEntity() => RepoEntity(
        fullName: fullName,
        description: description,
        language: language,
        starCount: starCount,
        starDelta: starDelta,
        forkCount: forkCount,
        accentArgb: color,
        trend: trend,
      );
}

extension DemoLanguageFixtureX on DemoLanguageFixture {
  LanguageEntity toEntity() => LanguageEntity(
        name: name,
        percent: percent,
        delta: delta,
        accentArgb: color,
      );
}

extension DemoAlertFixtureX on DemoAlertFixture {
  AlertEntity toEntity() => AlertEntity(
        repoFullName: repo,
        metric: metric,
        value: value,
        time: time,
        severity: _severityFromInt(severity),
      );
}

extension DemoContributorFixtureX on DemoContributorFixture {
  ContributorEntity toEntity() => ContributorEntity(
        login: login,
        contributions: contributions,
        avatarAccentArgb: avatarColor,
      );
}

AlertSeverity _severityFromInt(int i) {
  switch (i) {
    case 0:
      return AlertSeverity.info;
    case 1:
      return AlertSeverity.success;
    case 2:
      return AlertSeverity.warning;
    case 3:
    default:
      return AlertSeverity.danger;
  }
}
