import '../../../core/demo_data.dart';
import '../../../core/domain/data_provenance.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/github_api_support.dart';
import '../domain/discover_entities.dart';

/// 发现页离线种子数据。
/// 网络与本地缓存均不可用时兜底展示,确保首启即可见内容;
/// 联网后由 GitHub Search 实时数据覆盖。
class DiscoverSeed {
  const DiscoverSeed._();

  static RepoEntity _fromFixture(DemoRepoFixture f) => RepoEntity(
        fullName: f.fullName,
        description: f.description,
        language: f.language,
        starCount: f.starCount,
        starDelta: f.starDelta,
        forkCount: f.forkCount,
        accentArgb: GitHubApiSupport.languageColor(f.language),
        valueProvenance: DataProvenance.seed,
        trendProvenance: DataProvenance.seed,
      );

  /// 流行仓库种子(约 20 个):DemoData 流行 + 最近 + 精选补充。
  static List<RepoEntity> get seedPopularRepos {
    final base = [
      for (final f in DemoData.trending) _fromFixture(f),
      for (final f in DemoData.recent) _fromFixture(f),
    ];
    return [...base, ..._curatedExtras.map(_extraToEntity)];
  }

  /// Agent Skills 种子(离线兜底)。
  static List<SkillEntity> get seedAgentSkills {
    return [
      for (var i = 0; i < _skillDefs.length; i++)
        SkillEntity(
          repo: RepoEntity(
            fullName: _skillDefs[i].$1,
            description: _skillDefs[i].$2,
            language: 'TypeScript',
            starCount: _skillDefs[i].$4,
            starDelta: _skillDefs[i].$5,
            forkCount: _skillDefs[i].$6,
            accentArgb: GitHubApiSupport.languageColor('TypeScript'),
            valueProvenance: DataProvenance.seed,
            trendProvenance: DataProvenance.seed,
          ),
          category: _skillDefs[i].$3,
          source: 'seed',
          rank: i + 1,
          summary: _skillDefs[i].$2,
        ),
    ];
  }

  static RepoEntity _extraToEntity(_SeedExtra e) => RepoEntity(
        fullName: e.fullName,
        description: e.description,
        language: e.language,
        starCount: e.starCount,
        starDelta: e.starDelta,
        forkCount: e.forkCount,
        accentArgb: GitHubApiSupport.languageColor(e.language),
        valueProvenance: DataProvenance.seed,
        trendProvenance: DataProvenance.seed,
      );

  static const List<_SeedExtra> _curatedExtras = [
    _SeedExtra(
      'flutter/flutter',
      'UI toolkit for building natively compiled apps',
      'Dart',
      165000,
      120,
      24000,
    ),
    _SeedExtra(
      'microsoft/vscode',
      'Visual Studio Code editor',
      'TypeScript',
      162000,
      90,
      29000,
    ),
    _SeedExtra(
      'facebook/react',
      'The library for web and native user interfaces',
      'JavaScript',
      228000,
      80,
      46000,
    ),
    _SeedExtra(
      'tensorflow/tensorflow',
      'End-to-end open source ML platform',
      'C++',
      186000,
      70,
      87000,
    ),
    _SeedExtra(
      'pytorch/pytorch',
      'Tensors and dynamic neural networks',
      'Python',
      82000,
      110,
      22000,
    ),
    _SeedExtra(
      'rust-lang/rust',
      'Empowering everyone to build reliable software',
      'Rust',
      97000,
      60,
      12400,
    ),
  ];

  // (fullName, description, category, starCount, starDelta, forkCount)
  static const List<(String, String, String, int, int, int)> _skillDefs = [
    (
      'anthropics/skills',
      'Official Anthropic agent skills',
      'claude',
      38000,
      210,
      4200
    ),
    (
      'modelcontextprotocol/servers',
      'Reference MCP servers for the Model Context Protocol',
      'mcp',
      21640,
      684,
      1960
    ),
    (
      'openai/codex',
      'Cloud and local coding agent for software engineering',
      'agent',
      26840,
      738,
      1840
    ),
    (
      'anthropics/claude-code',
      "Anthropic's official CLI for Claude",
      'claude',
      18020,
      612,
      1240
    ),
    (
      'langchain-ai/langgraph',
      'Build resilient language agents as graphs',
      'agent',
      39280,
      548,
      6420
    ),
    (
      'punkpeye/awesome-mcp-servers',
      'A curated list of MCP servers',
      'mcp',
      12400,
      130,
      980
    ),
    ('wong2/mcp-cli', 'CLI for MCP servers', 'mcp', 3200, 80, 210),
    (
      'harishsg993010/awesome-claude-skills',
      'A curated list of Claude skills',
      'claude',
      2100,
      60,
      320
    ),
    ('dotcoin/mcp-skills', 'A collection of MCP skills', 'mcp', 980, 40, 120),
    (
      'e2b-dev/claude-code-skills',
      'Claude code skills by E2B',
      'claude',
      1500,
      50,
      180
    ),
    (
      'VoltAgent/awesome-agent-skills',
      'Curated agent skills for Claude/Codex/Cursor/Copilot',
      'agent',
      4200,
      180,
      360
    ),
    (
      'JackyST0/awesome-agent-skills',
      'Curated index of agent skills with SKILL.md',
      'agent',
      2600,
      120,
      240
    ),
  ];
}

class _SeedExtra {
  const _SeedExtra(
    this.fullName,
    this.description,
    this.language,
    this.starCount,
    this.starDelta,
    this.forkCount,
  );

  final String fullName;
  final String description;
  final String language;
  final int starCount;
  final int starDelta;
  final int forkCount;
}
