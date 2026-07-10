import '../../../core/domain/repo_entity.dart';
import '../domain/discover_entities.dart';

class DiscoverQueries {
  const DiscoverQueries._();

  static const String trending = 'stars:>1000';
  static const String skills = 'topic:agent-skills OR topic:claude-skills OR topic:mcp stars:>50';
  static const String trendingCache = 'discover_trending_repos';
  static const String skillsCache = 'discover_agent_skills';
  static const String profilesCache = 'discover_profiles';

  static const List<String> officialLogins = [
    'openai',
    'anthropics',
    'microsoft',
    'langchain-ai',
    'crewAIInc',
    'modelcontextprotocol',
    'vercel',
    'google',
    'meta-llama',
    'huggingface',
  ];

  static const List<String> peopleLogins = [
    'karpathy',
    'simonw',
    'swyxio',
    'hwchase17',
    'jerryjliu',
    'gdb',
    'fchollet',
    'soumith',
    'TimDettmers',
    'shreyashankar',
  ];

  static const Map<String, String> featuredReposByLogin = {
    'openai': 'openai/openai-agents-python',
    'anthropics': 'anthropics/skills',
    'microsoft': 'microsoft/autogen',
    'langchain-ai': 'langchain-ai/langchain',
    'crewAIInc': 'crewAIInc/crewAI',
    'modelcontextprotocol': 'modelcontextprotocol/servers',
    'vercel': 'vercel/ai',
    'google': 'google-gemini/gemini-cli',
    'meta-llama': 'meta-llama/llama-cookbook',
    'huggingface': 'huggingface/transformers',
    'karpathy': 'karpathy/nanoGPT',
    'simonw': 'simonw/llm',
    'swyxio': 'swyxio/ai-notes',
    'hwchase17': 'langchain-ai/langchain',
    'jerryjliu': 'run-llama/llama_index',
    'gdb': 'openai/openai-cookbook',
    'fchollet': 'keras-team/keras',
    'soumith': 'pytorch/pytorch',
    'TimDettmers': 'bitsandbytes-foundation/bitsandbytes',
    'shreyashankar': 'lotus-data/lotus',
  };

  static List<String> profileLogins(DiscoverProfileKind kind) {
    return kind == DiscoverProfileKind.official ? officialLogins : peopleLogins;
  }

  static String featuredRepoForLogin(String login) {
    return featuredReposByLogin[login] ?? '$login/$login';
  }

  static String deriveSkillCategory(RepoEntity repo) {
    final text = '${repo.fullName} ${repo.description}'.toLowerCase();
    if (text.contains('claude')) return 'claude';
    if (text.contains('cursor')) return 'cursor';
    if (text.contains('copilot')) return 'copilot';
    if (text.contains('mcp')) return 'mcp';
    if (text.contains('langchain') || text.contains('langgraph')) {
      return 'agent';
    }
    return 'other';
  }

  static String pageKey(String base, int page, int perPage) {
    return '$base:p$page:n$perPage';
  }

  static List<T> slice<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;
    if (start >= items.length) return const [];
    final end = (start + perPage).clamp(0, items.length);
    return items.sublist(start, end);
  }
}
