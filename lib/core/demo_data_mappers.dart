import 'demo_data.dart';
import 'domain/contributor_entity.dart';
import 'domain/repo_entity.dart';

/* 
*Demo fixture → domain 实体的映射集合。
*仅在 data 层(LocalXxxRepository)使用,domain 不允许依赖本文件。
*/
extension DemoRepoFixtureX on DemoRepoFixture {
  RepoEntity toEntity() =>
      RepoEntity(fullName: fullName, description: description, language: language, starCount: starCount, starDelta: starDelta, forkCount: forkCount, accentArgb: color, trend: trend);
}

extension DemoLanguageFixtureX on DemoLanguageFixture {
  LanguageEntity toEntity() => LanguageEntity(name: name, percent: percent, delta: delta, accentArgb: color);
}

extension DemoContributorFixtureX on DemoContributorFixture {
  ContributorEntity toEntity() => ContributorEntity(login: login, contributions: contributions, avatarAccentArgb: avatarColor);
}
