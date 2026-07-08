import '../domain/ai_news_item.dart';

/* 
*AI 动态内置种子数据。
*当本地缓存为空且远端不可用时,作为首页即时可渲染的兜底内容,
*避免首启即空白或错误态。命名为 seed 而非 mock:随产品发布,
*不是测试替身。列表内容随版本迭代,不应被写入本地缓存。
*/
class AiNewsSeedData {
  const AiNewsSeedData._();

  static final List<AiNewsItem> items = [
    AiNewsItem(
      id: 'seed-001',
      category: AiNewsCategory.aiModels,
      title: '多模态大模型进入推理与工具调用竞争阶段',
      titleEn: 'Multimodal models enter the reasoning and tool-use race',
      summary: '头部模型在长上下文、视觉理解与函数调用上持续迭代,应用层开始围绕 Agent 工作流重构。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 94,
      selected: true,
    ),
    AiNewsItem(
      id: 'seed-002',
      category: AiNewsCategory.aiProducts,
      title: 'AI 编程助手从补全走向任务代理',
      titleEn: 'AI coding assistants shift from completion to task agents',
      summary: 'Cursor、Windsurf 与开源 coding agent 持续迭代,代码工作流正在从行级补全转向多文件任务代理。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 90,
      selected: true,
    ),
    AiNewsItem(
      id: 'seed-003',
      category: AiNewsCategory.paper,
      title: 'RAG 评测与重排成为企业落地重点',
      titleEn: 'RAG evaluation and reranking become enterprise priorities',
      summary: '检索、重排、评测和知识库同步成为企业 AI 落地的基础设施,简单 demo 正在让位于工程化链路。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 86,
      selected: false,
    ),
    AiNewsItem(
      id: 'seed-004',
      category: AiNewsCategory.tip,
      title: 'MCP 正在成为模型连接工具的事实标准',
      titleEn: 'MCP is becoming the de facto standard for tool integration',
      summary: 'MCP 把模型、数据源与本地应用用统一接口连接起来,生态项目与脚手架增长明显。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 83,
      selected: false,
    ),
    AiNewsItem(
      id: 'seed-005',
      category: AiNewsCategory.industry,
      title: '端侧推理工具链继续扩张',
      titleEn: 'On-device inference toolchains keep expanding',
      summary: 'Ollama、llama.cpp 与端侧模型工具链继续扩张,隐私、低延迟和离线能力成为关键卖点。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 79,
      selected: false,
    ),
    AiNewsItem(
      id: 'seed-006',
      category: AiNewsCategory.aiModels,
      title: '小型化模型在端侧与边缘场景升温',
      titleEn: 'Smaller models heat up for edge and on-device scenarios',
      summary: '蒸馏与量化让 7B 级别模型在消费级硬件上可用,端侧智能体开始进入真实产品。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 76,
      selected: false,
    ),
    AiNewsItem(
      id: 'seed-007',
      category: AiNewsCategory.industry,
      title: '推理网关与多模型路由成为新基础设施',
      titleEn: 'Inference gateways and multi-model routing become new infra',
      summary: '团队接入多模型后,模型路由、成本观测和评测流水线成为新的工程基础设施。',
      source: 'GitHub News',
      url: 'https://github.com',
      permalink: 'https://github.com',
      publishedAt: _now,
      score: 73,
      selected: false,
    ),
  ];

  static final DateTime _now = DateTime.now();
}
