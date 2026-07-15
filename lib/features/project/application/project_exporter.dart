import 'dart:io';

import '../../../core/i18n/app_localizations.dart';
import '../domain/project_repository.dart';

class ProjectReportCopy {
  const ProjectReportCopy(
      {required this.title,
      required this.generatedAt,
      required this.repositoryCount,
      required this.contributorCount,
      required this.popularRepositories,
      required this.noRepositories,
      required this.language,
      required this.stars,
      required this.newStars,
      required this.forks,
      required this.description,
      required this.contributors,
      required this.noContributors,
      required this.contributionUnit});

  factory ProjectReportCopy.fromLocalizations(AppLocalizations l10n) {
    return ProjectReportCopy(
      title: l10n.tr('project.report.title'),
      generatedAt: l10n.tr('project.report.generated_at'),
      repositoryCount: l10n.tr('project.report.repo_count'),
      contributorCount: l10n.tr('project.report.contributor_count'),
      popularRepositories: l10n.tr('project.report.popular_repos'),
      noRepositories: l10n.tr('project.report.no_repos'),
      language: l10n.tr('project.report.language'),
      stars: l10n.tr('project.report.stars'),
      newStars: l10n.tr('project.report.new_stars'),
      forks: l10n.tr('project.report.forks'),
      description: l10n.tr('project.report.description'),
      contributors: l10n.tr('project.report.contributors'),
      noContributors: l10n.tr('project.report.no_contributors'),
      contributionUnit: l10n.tr('project.report.contribution_unit'),
    );
  }

  static const zhCN = ProjectReportCopy(
    title: 'GitHub 情报站深度报告',
    generatedAt: '生成时间',
    repositoryCount: '仓库数量',
    contributorCount: '贡献者数量',
    popularRepositories: '热门仓库',
    noRepositories: '暂无仓库数据。',
    language: '语言',
    stars: 'Star',
    newStars: '新增 Star',
    forks: 'Fork',
    description: '简介',
    contributors: '贡献者',
    noContributors: '暂无贡献者数据。',
    contributionUnit: '次贡献',
  );

  static const enUS = ProjectReportCopy(
    title: 'GitHub Intelligence Report',
    generatedAt: 'Generated at',
    repositoryCount: 'Repository count',
    contributorCount: 'Contributor count',
    popularRepositories: 'Popular repositories',
    noRepositories: 'No repository data.',
    language: 'Language',
    stars: 'Stars',
    newStars: 'New stars',
    forks: 'Forks',
    description: 'Description',
    contributors: 'Contributors',
    noContributors: 'No contributor data.',
    contributionUnit: 'contributions',
  );

  final String title;
  final String generatedAt;
  final String repositoryCount;
  final String contributorCount;
  final String popularRepositories;
  final String noRepositories;
  final String language;
  final String stars;
  final String newStars;
  final String forks;
  final String description;
  final String contributors;
  final String noContributors;
  final String contributionUnit;
}

String formatProjectDigestMarkdown(ProjectDigest digest, {required DateTime generatedAt, required ProjectReportCopy copy}) {
  final buffer = StringBuffer()
    ..writeln('# ${copy.title}')
    ..writeln()
    ..writeln('- ${copy.generatedAt}: ${generatedAt.toLocal()}')
    ..writeln('- ${copy.repositoryCount}: ${digest.repos.length}')
    ..writeln('- ${copy.contributorCount}: ${digest.contributors.length}')
    ..writeln()
    ..writeln('## ${copy.popularRepositories}')
    ..writeln();

  if (digest.repos.isEmpty) {
    buffer.writeln(copy.noRepositories);
  } else {
    for (final repo in digest.repos) {
      buffer
        ..writeln('### ${repo.fullName}')
        ..writeln()
        ..writeln('- ${copy.language}: ${repo.language}')
        ..writeln('- ${copy.stars}: ${repo.starCount}')
        ..writeln('- ${copy.newStars}: ${repo.starDelta}')
        ..writeln('- ${copy.forks}: ${repo.forkCount}')
        ..writeln('- ${copy.description}: ${repo.description}')
        ..writeln();
    }
  }

  buffer
    ..writeln('## ${copy.contributors}')
    ..writeln();
  if (digest.contributors.isEmpty) {
    buffer.writeln(copy.noContributors);
  } else {
    for (final contributor in digest.contributors) {
      buffer.writeln('- @${contributor.login}: ${contributor.contributions} ${copy.contributionUnit}');
    }
  }
  return buffer.toString();
}

Future<File> writeProjectDigestMarkdown({
  required ProjectDigest digest,
  required Directory outputDirectory,
  required DateTime generatedAt,
  required ProjectReportCopy copy,
}) async {
  final reportsDir = Directory('${outputDirectory.path}/GitHubIntelligence/reports');
  await reportsDir.create(recursive: true);
  final file = File('${reportsDir.path}/report_${_stamp(generatedAt)}.md');
  return file.writeAsString(formatProjectDigestMarkdown(digest, generatedAt: generatedAt, copy: copy));
}

String _stamp(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return [value.year.toString(), two(value.month), two(value.day), '_', two(value.hour), two(value.minute), two(value.second)].join();
}
