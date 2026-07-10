import '../../../core/demo_data.dart';
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
          ),
          category: _skillDefs[i].$3,
          source: 'seed',
          rank: i + 1,
          summary: _skillDefs[i].$2,
        ),
    ];
  }

  static List<DiscoverProfileEntity> seedProfiles(DiscoverProfileKind kind) => kind == DiscoverProfileKind.official ? _officialProfiles : _peopleProfiles;

  static RepoEntity _extraToEntity(_SeedExtra e) => RepoEntity(
        fullName: e.fullName,
        description: e.description,
        language: e.language,
        starCount: e.starCount,
        starDelta: e.starDelta,
        forkCount: e.forkCount,
        accentArgb: GitHubApiSupport.languageColor(e.language),
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
      4200,
    ),
    (
      'modelcontextprotocol/servers',
      'Reference MCP servers for the Model Context Protocol',
      'mcp',
      21640,
      684,
      1960,
    ),
    (
      'openai/codex',
      'Cloud and local coding agent for software engineering',
      'agent',
      26840,
      738,
      1840,
    ),
    (
      'anthropics/claude-code',
      "Anthropic's official CLI for Claude",
      'claude',
      18020,
      612,
      1240,
    ),
    (
      'langchain-ai/langgraph',
      'Build resilient language agents as graphs',
      'agent',
      39280,
      548,
      6420,
    ),
    (
      'punkpeye/awesome-mcp-servers',
      'A curated list of MCP servers',
      'mcp',
      12400,
      130,
      980,
    ),
    ('wong2/mcp-cli', 'CLI for MCP servers', 'mcp', 3200, 80, 210),
    (
      'harishsg993010/awesome-claude-skills',
      'A curated list of Claude skills',
      'claude',
      2100,
      60,
      320,
    ),
    ('dotcoin/mcp-skills', 'A collection of MCP skills', 'mcp', 980, 40, 120),
    (
      'e2b-dev/claude-code-skills',
      'Claude code skills by E2B',
      'claude',
      1500,
      50,
      180,
    ),
    (
      'VoltAgent/awesome-agent-skills',
      'Curated agent skills for Claude/Codex/Cursor/Copilot',
      'agent',
      4200,
      180,
      360,
    ),
    (
      'JackyST0/awesome-agent-skills',
      'Curated index of agent skills with SKILL.md',
      'agent',
      2600,
      120,
      240,
    ),
  ];

  static const List<DiscoverProfileEntity> _officialProfiles = [
    DiscoverProfileEntity(
      login: 'openai',
      name: 'OpenAI',
      type: 'Organization',
      bio: 'Official OpenAI GitHub organization',
      publicRepos: 261,
      followers: 125697,
      avatarUrl: 'https://github.com/openai.png',
      htmlUrl: 'https://github.com/openai',
      featuredRepoFullName: 'openai/openai-agents-python',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'anthropics',
      name: 'Anthropic',
      type: 'Organization',
      bio: 'Official Anthropic GitHub organization',
      publicRepos: 92,
      followers: 75251,
      avatarUrl: 'https://github.com/anthropics.png',
      htmlUrl: 'https://github.com/anthropics',
      featuredRepoFullName: 'anthropics/skills',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'microsoft',
      name: 'Microsoft',
      type: 'Organization',
      bio: 'Official Microsoft GitHub organization',
      publicRepos: 8173,
      followers: 124666,
      avatarUrl: 'https://github.com/microsoft.png',
      htmlUrl: 'https://github.com/microsoft',
      featuredRepoFullName: 'microsoft/autogen',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'langchain-ai',
      name: 'LangChain',
      type: 'Organization',
      bio: 'Agent engineering platform and LangGraph ecosystem',
      publicRepos: 251,
      followers: 20669,
      avatarUrl: 'https://github.com/langchain-ai.png',
      htmlUrl: 'https://github.com/langchain-ai',
      featuredRepoFullName: 'langchain-ai/langchain',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'crewAIInc',
      name: 'crewAI',
      type: 'Organization',
      bio: 'Framework for orchestrating autonomous AI agents',
      publicRepos: 32,
      followers: 2138,
      avatarUrl: 'https://github.com/crewAIInc.png',
      htmlUrl: 'https://github.com/crewAIInc',
      featuredRepoFullName: 'crewAIInc/crewAI',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'modelcontextprotocol',
      name: 'Model Context Protocol',
      type: 'Organization',
      bio: 'Reference implementation and SDKs for MCP',
      publicRepos: 42,
      followers: 48674,
      avatarUrl: 'https://github.com/modelcontextprotocol.png',
      htmlUrl: 'https://github.com/modelcontextprotocol',
      featuredRepoFullName: 'modelcontextprotocol/servers',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'vercel',
      name: 'Vercel',
      type: 'Organization',
      bio: 'Frontend cloud platform and AI SDK ecosystem',
      publicRepos: 237,
      followers: 29517,
      avatarUrl: 'https://github.com/vercel.png',
      htmlUrl: 'https://github.com/vercel',
      featuredRepoFullName: 'vercel/ai',
      kind: DiscoverProfileKind.official,
    ),
    DiscoverProfileEntity(
      login: 'huggingface',
      name: 'Hugging Face',
      type: 'Organization',
      bio: 'Open-source machine learning models and tooling',
      publicRepos: 452,
      followers: 65530,
      avatarUrl: 'https://github.com/huggingface.png',
      htmlUrl: 'https://github.com/huggingface',
      featuredRepoFullName: 'huggingface/transformers',
      kind: DiscoverProfileKind.official,
    ),
  ];

  static const List<DiscoverProfileEntity> _peopleProfiles = [
    DiscoverProfileEntity(
      login: 'karpathy',
      name: 'Andrej Karpathy',
      type: 'User',
      bio: 'AI researcher, educator, and builder',
      publicRepos: 63,
      followers: 208119,
      avatarUrl: 'https://github.com/karpathy.png',
      htmlUrl: 'https://github.com/karpathy',
      featuredRepoFullName: 'karpathy/nanoGPT',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'simonw',
      name: 'Simon Willison',
      type: 'User',
      bio: 'Datasette, LLM tooling, and AI engineering notes',
      publicRepos: 972,
      followers: 15819,
      avatarUrl: 'https://github.com/simonw.png',
      htmlUrl: 'https://github.com/simonw',
      featuredRepoFullName: 'simonw/llm',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'swyxio',
      name: 'swyx',
      type: 'User',
      bio: 'AI engineer and community builder',
      publicRepos: 725,
      followers: 7587,
      avatarUrl: 'https://github.com/swyxio.png',
      htmlUrl: 'https://github.com/swyxio',
      featuredRepoFullName: 'swyxio/ai-notes',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'hwchase17',
      name: 'Harrison Chase',
      type: 'User',
      bio: 'LangChain founder',
      publicRepos: 67,
      followers: 9937,
      avatarUrl: 'https://github.com/hwchase17.png',
      htmlUrl: 'https://github.com/hwchase17',
      featuredRepoFullName: 'langchain-ai/langchain',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'jerryjliu',
      name: 'Jerry Liu',
      type: 'User',
      bio: 'LlamaIndex co-founder and AI infrastructure builder',
      publicRepos: 54,
      followers: 4328,
      avatarUrl: 'https://github.com/jerryjliu.png',
      htmlUrl: 'https://github.com/jerryjliu',
      featuredRepoFullName: 'run-llama/llama_index',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'fchollet',
      name: 'François Chollet',
      type: 'User',
      bio: 'Keras creator and AI researcher',
      publicRepos: 16,
      followers: 18102,
      avatarUrl: 'https://github.com/fchollet.png',
      htmlUrl: 'https://github.com/fchollet',
      featuredRepoFullName: 'keras-team/keras',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'soumith',
      name: 'Soumith Chintala',
      type: 'User',
      bio: 'PyTorch co-creator',
      publicRepos: 170,
      followers: 13392,
      avatarUrl: 'https://github.com/soumith.png',
      htmlUrl: 'https://github.com/soumith',
      featuredRepoFullName: 'pytorch/pytorch',
      kind: DiscoverProfileKind.people,
    ),
    DiscoverProfileEntity(
      login: 'shreyashankar',
      name: 'Shreya Shankar',
      type: 'User',
      bio: 'AI systems and data-centric AI researcher',
      publicRepos: 72,
      followers: 1907,
      avatarUrl: 'https://github.com/shreyashankar.png',
      htmlUrl: 'https://github.com/shreyashankar',
      featuredRepoFullName: 'lotus-data/lotus',
      kind: DiscoverProfileKind.people,
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
