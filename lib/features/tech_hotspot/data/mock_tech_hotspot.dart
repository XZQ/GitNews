import '../domain/tech_hotspot_models.dart';

/// 技术热点 mock 数据。
class MockTechHotspot {
  const MockTechHotspot._();

  static const List<LanguageStat> languages = [
    LanguageStat(
      name: 'TypeScript',
      percent: 24.8,
      delta: 1.8,
      color: 0xFF3178C6,
      repoCount: 1820,
    ),
    LanguageStat(
      name: 'Python',
      percent: 21.4,
      delta: 0.9,
      color: 0xFF3572A5,
      repoCount: 2310,
    ),
    LanguageStat(
      name: 'Rust',
      percent: 12.6,
      delta: 3.2,
      color: 0xFFDEA584,
      repoCount: 940,
    ),
    LanguageStat(
      name: 'Go',
      percent: 10.2,
      delta: 0.6,
      color: 0xFF00ADD8,
      repoCount: 1180,
    ),
    LanguageStat(
      name: 'Kotlin',
      percent: 7.4,
      delta: -0.4,
      color: 0xFFA97BFF,
      repoCount: 620,
    ),
    LanguageStat(
      name: 'Swift',
      percent: 5.8,
      delta: 0.2,
      color: 0xFFFA7343,
      repoCount: 410,
    ),
    LanguageStat(
      name: 'Java',
      percent: 5.1,
      delta: -1.2,
      color: 0xFFB07219,
      repoCount: 870,
    ),
  ];

  static const List<TechTopic> topics = [
    TechTopic(
      id: 't-001',
      name: '生成式模型',
      category: 'AI',
      heat: 96,
      growth: 18.4,
      mentions: 8420,
      relatedRepos: 312,
      summary: 'GPT/Claude/Gemini 等大模型生态持续扩张,推理框架与 Agent 框架进入主流。',
    ),
    TechTopic(
      id: 't-002',
      name: 'Rust 生态',
      category: 'Systems',
      heat: 88,
      growth: 12.6,
      mentions: 5210,
      relatedRepos: 184,
      summary: 'Rust 在编译器、数据库、AI 推理框架领域加速替代 C++。axum / tokio 持续活跃。',
    ),
    TechTopic(
      id: 't-003',
      name: '边缘计算',
      category: 'Cloud',
      heat: 72,
      growth: 8.9,
      mentions: 3120,
      relatedRepos: 96,
      summary:
          'WebAssembly + Edge Runtime 推动边缘函数进入主流。Cloudflare、Vercel、Deno 三足鼎立。',
    ),
    TechTopic(
      id: 't-004',
      name: 'Agent 框架',
      category: 'AI',
      heat: 91,
      growth: 24.1,
      mentions: 6180,
      relatedRepos: 142,
      summary: 'LangGraph、AutoGen、OpenAI Swarm 等长任务 Agent 框架爆发,带动 MCP 协议标准化。',
    ),
    TechTopic(
      id: 't-005',
      name: 'Bun 运行时',
      category: 'Frontend',
      heat: 68,
      growth: 14.2,
      mentions: 2840,
      relatedRepos: 58,
      summary: 'Bun 1.0 后稳定性大幅提升,benchmark 持续领先 Node.js 与 Deno。',
    ),
    TechTopic(
      id: 't-006',
      name: '向量数据库',
      category: 'Data',
      heat: 76,
      growth: 9.3,
      mentions: 3420,
      relatedRepos: 87,
      summary: 'pgvector / qdrant / chroma / milvus 四方角力,RAG 场景成为标配。',
    ),
    TechTopic(
      id: 't-007',
      name: 'Zig',
      category: 'Systems',
      heat: 54,
      growth: 21.8,
      mentions: 1820,
      relatedRepos: 42,
      summary: 'Zig 在系统编程领域关注度暴涨,Bun / TigerBeetle 等明星项目背书。',
    ),
    TechTopic(
      id: 't-008',
      name: 'Flutter 多平台',
      category: 'Mobile',
      heat: 62,
      growth: 4.8,
      mentions: 2410,
      relatedRepos: 73,
      summary: 'Flutter 桌面端成熟,Impeller 引擎全平台落地,Web 端性能持续优化。',
    ),
  ];

  static const List<TechHeatPoint> heatTrend = [
    TechHeatPoint(label: '周一', value: 62),
    TechHeatPoint(label: '周二', value: 70),
    TechHeatPoint(label: '周三', value: 68),
    TechHeatPoint(label: '周四', value: 78),
    TechHeatPoint(label: '周五', value: 86),
    TechHeatPoint(label: '周六', value: 80),
    TechHeatPoint(label: '周日', value: 92),
  ];

  /// 顶部热门标签。
  static const List<String> hotTags = [
    'LLM',
    'Agent',
    'RAG',
    'MCP',
    'Wasm',
    'Edge',
    'Rust',
    'Bun',
    'Zig',
    'Vector DB',
    'Flutter',
    'Tokio',
    'Postgres',
    'K8s',
    'eBPF',
  ];
}
