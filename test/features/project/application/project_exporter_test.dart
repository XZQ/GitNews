import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/project/application/project_exporter.dart';
import 'package:github_news/features/project/domain/project_repository.dart';

RepoEntity _repo(String fullName, {String language = 'Dart'}) {
  return RepoEntity(fullName: fullName, description: 'A useful project', language: language, starCount: 1200, starDelta: 80, forkCount: 30, accentArgb: 0xFF00A389);
}

ContributorEntity _contributor(String login, {int contributions = 42}) {
  return ContributorEntity(login: login, contributions: contributions, avatarAccentArgb: 0xFF6366F1);
}

void main() {
  test('formatProjectDigestMarkdown should include repos and contributors', () {
    final markdown = formatProjectDigestMarkdown(
      ProjectDigest(
        repos: [_repo('openai/codex', language: 'TypeScript')],
        contributors: [_contributor('maintainer', contributions: 42)],
        primaryTrend: const [],
        secondaryTrend: const [],
        activities: const [],
      ),
      generatedAt: DateTime.utc(2026, 7, 4, 12),
      copy: ProjectReportCopy.zhCN,
    );

    expect(markdown, contains('# GitHub 情报站深度报告'));
    expect(markdown, contains('openai/codex'));
    expect(markdown, contains('@maintainer'));
  });

  test('English report contains no Chinese headings or field labels', () {
    final markdown = formatProjectDigestMarkdown(
      ProjectDigest(repos: [_repo('openai/codex')], contributors: [_contributor('maintainer')], primaryTrend: const [], secondaryTrend: const [], activities: const []),
      generatedAt: DateTime.utc(2026, 7, 4, 12),
      copy: ProjectReportCopy.enUS,
    );

    expect(markdown, contains('# GitHub Intelligence Report'));
    expect(markdown, contains('## Popular repositories'));
    expect(markdown, isNot(matches(RegExp(r'[\u4e00-\u9fff]'))));
  });

  test('writeProjectDigestMarkdown should write report file', () async {
    final temp = await Directory.systemTemp.createTemp('github_news_report_');
    addTearDown(() async => temp.delete(recursive: true));

    final file = await writeProjectDigestMarkdown(
      digest: ProjectDigest(repos: [_repo('vercel/next.js')], contributors: const [], primaryTrend: const [], secondaryTrend: const [], activities: const []),
      outputDirectory: temp,
      generatedAt: DateTime.utc(2026, 7, 4, 12, 30, 5),
      copy: ProjectReportCopy.enUS,
    );

    expect(file.path, contains('report_20260704_123005.md'));
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('vercel/next.js'));
  });
}
