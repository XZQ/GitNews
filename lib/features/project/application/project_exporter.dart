import 'dart:io';

import '../domain/project_repository.dart';

String formatProjectDigestMarkdown(
  ProjectDigest digest, {
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# GitHub 情报站深度报告')
    ..writeln()
    ..writeln('- 生成时间: ${generatedAt.toLocal()}')
    ..writeln('- 仓库数量: ${digest.repos.length}')
    ..writeln('- 贡献者数量: ${digest.contributors.length}')
    ..writeln()
    ..writeln('## 热门仓库')
    ..writeln();

  if (digest.repos.isEmpty) {
    buffer.writeln('暂无仓库数据。');
  } else {
    for (final repo in digest.repos) {
      buffer
        ..writeln('### ${repo.fullName}')
        ..writeln()
        ..writeln('- 语言: ${repo.language}')
        ..writeln('- Star: ${repo.starCount}')
        ..writeln('- 新增 Star: ${repo.starDelta}')
        ..writeln('- Fork: ${repo.forkCount}')
        ..writeln('- 简介: ${repo.description}')
        ..writeln();
    }
  }

  buffer
    ..writeln('## 贡献者')
    ..writeln();
  if (digest.contributors.isEmpty) {
    buffer.writeln('暂无贡献者数据。');
  } else {
    for (final contributor in digest.contributors) {
      buffer.writeln(
        '- @${contributor.login}: ${contributor.contributions} 次贡献',
      );
    }
  }

  return buffer.toString();
}

Future<File> writeProjectDigestMarkdown({
  required ProjectDigest digest,
  required Directory outputDirectory,
  required DateTime generatedAt,
}) async {
  final reportsDir = Directory('${outputDirectory.path}/GitHub情报站/reports');
  await reportsDir.create(recursive: true);
  final fileName = 'report_${_stamp(generatedAt)}.md';
  final file = File('${reportsDir.path}/$fileName');
  return file.writeAsString(
    formatProjectDigestMarkdown(digest, generatedAt: generatedAt),
  );
}

String _stamp(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return [
    value.year.toString(),
    two(value.month),
    two(value.day),
    '_',
    two(value.hour),
    two(value.minute),
    two(value.second),
  ].join();
}
