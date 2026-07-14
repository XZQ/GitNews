import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/domain/github_repo_link_extractor.dart';

void main() {
  group('extractGitHubRepoLinks', () {
    test('extracts owner/repo from urls and prose', () {
      final repos = extractGitHubRepoLinks([
        'Check https://github.com/openai/whisper for details',
        'also see github.com/ggerganov/llama.cpp.',
      ]);
      expect(repos, ['openai/whisper', 'ggerganov/llama.cpp']);
    });

    test('strips .git suffix and trailing punctuation', () {
      final repos = extractGitHubRepoLinks([
        'clone https://github.com/foo/bar.git now',
      ]);
      expect(repos, ['foo/bar']);
    });

    test('ignores reserved paths and dedups case-insensitively', () {
      final repos = extractGitHubRepoLinks([
        'https://github.com/topics/ai',
        'https://github.com/features/copilot',
        'https://github.com/Foo/Bar and https://github.com/foo/bar',
      ]);
      expect(repos, ['Foo/Bar']);
    });

    test('respects limit and empty input', () {
      final repos = extractGitHubRepoLinks(
        [for (var i = 0; i < 10; i++) 'https://github.com/user/repo$i'],
        limit: 3,
      );
      expect(repos, hasLength(3));
      expect(extractGitHubRepoLinks(['no links here']), isEmpty);
    });
  });
}
