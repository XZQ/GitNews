import '../domain/tech_hotspot_models.dart';

/* 
*内置种子数据。
*在接入真实远端之前,作为 [TechHotspotRepository] 的 in-memory 数据源。
*命名为 seed 而非 mock:这些数据随产品发布,不是测试替身。
*/
class TechHotspotSeedData {
  const TechHotspotSeedData._();

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
      name: '多模态模型',
      category: 'AI',
      heat: 96,
      growth: 18.4,
      mentions: 8420,
      relatedRepos: 312,
      summary: 'GPT、Claude、Gemini 等模型进入多模态与推理能力竞争,应用层开始围绕工具调用重构。',
    ),
    TechTopic(
      id: 't-002',
      name: 'Agent 框架',
      category: 'Agent',
      heat: 94,
      growth: 24.1,
      mentions: 6180,
      relatedRepos: 142,
      summary: 'LangGraph、AutoGen、CrewAI 等长任务 Agent 框架升温,企业场景开始关注编排与可观测性。',
    ),
    TechTopic(
      id: 't-003',
      name: 'MCP 协议',
      category: 'Agent',
      heat: 91,
      growth: 31.7,
      mentions: 5740,
      relatedRepos: 118,
      summary: 'MCP 正在成为模型连接工具、数据源与本地应用的通用接口,生态项目增长明显。',
    ),
    TechTopic(
      id: 't-004',
      name: 'AI Coding 工具',
      category: 'DevTools',
      heat: 89,
      growth: 22.6,
      mentions: 6940,
      relatedRepos: 166,
      summary:
          'Cursor、Windsurf、Claude Code 与开源 coding agent 持续迭代,代码工作流从补全走向任务代理。',
    ),
    TechTopic(
      id: 't-005',
      name: 'RAG 工程化',
      category: 'Data',
      heat: 82,
      growth: 12.4,
      mentions: 4380,
      relatedRepos: 126,
      summary: '检索、重排、评测和知识库同步成为企业 AI 落地的基础设施,简单 demo 正在让位于工程化链路。',
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
      name: '本地推理',
      category: 'Infra',
      heat: 74,
      growth: 16.8,
      mentions: 3860,
      relatedRepos: 92,
      summary: 'Ollama、llama.cpp 与端侧模型工具链继续扩张,隐私、低延迟和离线能力成为关键卖点。',
    ),
    TechTopic(
      id: 't-008',
      name: 'AI Infra',
      category: 'Infra',
      heat: 71,
      growth: 10.6,
      mentions: 2940,
      relatedRepos: 78,
      summary: '推理网关、模型路由、成本观测和评测流水线成为团队接入多模型后的新基础设施。',
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

  static const List<String> hotTags = [
    'LLM',
    'Agent',
    'MCP',
    'AI Coding',
    'RAG',
    'Context',
    'Evals',
    'Workflow',
    'Local LLM',
    'Tool Use',
    'Vector DB',
    'Inference',
    'Open Source',
    'Observability',
    'Memory',
    'PromptOps',
  ];
}
