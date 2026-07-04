class TechHotspotTopicQuery {
  const TechHotspotTopicQuery({
    required this.id,
    required this.name,
    required this.category,
    required this.query,
    required this.summary,
  });

  final String id;
  final String name;
  final String category;
  final String query;
  final String summary;
}

const List<TechHotspotTopicQuery> techHotspotTopicQueries = [
  TechHotspotTopicQuery(
    id: 'github-agent',
    name: 'Agent 框架',
    category: 'Agent',
    query: 'agent OR ai-agent OR llm-agent OR langgraph OR autogen',
    summary: 'GitHub 上 Agent 编排、长任务代理和多智能体项目的综合热度。',
  ),
  TechHotspotTopicQuery(
    id: 'github-mcp',
    name: 'MCP 协议',
    category: 'Agent',
    query: 'mcp OR model-context-protocol OR modelcontextprotocol',
    summary: '模型连接工具、数据源和本地应用的开放协议生态热度。',
  ),
  TechHotspotTopicQuery(
    id: 'github-ai-coding',
    name: 'AI Coding 工具',
    category: 'DevTools',
    query: 'coding agent OR copilot OR code assistant OR claude-code OR codex',
    summary: '从代码补全到任务代理的 AI Coding 项目增长趋势。',
  ),
  TechHotspotTopicQuery(
    id: 'github-rag',
    name: 'RAG 工程化',
    category: 'Data',
    query: 'rag OR retrieval augmented generation OR vector database',
    summary: '检索增强生成、向量数据库、重排和知识库链路的工程热度。',
  ),
  TechHotspotTopicQuery(
    id: 'github-local-llm',
    name: '本地推理',
    category: 'Infra',
    query: 'llama.cpp OR ollama OR vllm OR local llm',
    summary: '本地模型推理、端侧部署和低延迟推理工具链热度。',
  ),
];
