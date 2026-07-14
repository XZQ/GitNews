import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/preferences/ai_digest_config_controller.dart';
import '../data/ai_digest_llm_client.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_providers.dart';

/*
*AI 日报:用用户自带的 OpenAI 兼容凭据,对「本地资讯库中今天的条目」
*生成一段中文摘要。
*边界:
*- 未配置 Key 时不发任何请求,UI 只显示引导
*- 结果按天缓存在 prefs(`ai_digest:YYYY-MM-DD`),不重复计费
*- 失败明确报错,不伪造摘要
*/

final aiDigestDioProvider = Provider<Dio>(
  (ref) => DioClient.create(
    baseUrl: ApiEndpointsConfig.aiDigestDefaultBaseUrl,
    headers: const {'Accept': 'application/json'},
  ),
);

final aiDigestLlmClientProvider = Provider<AiDigestLlmClient>(
  (ref) => AiDigestLlmClient(ref.watch(aiDigestDioProvider)),
);

// 今日日报文本;null = 尚未生成。
final aiDigestNotifierProvider = AsyncNotifierProvider<AiDigestNotifier, String?>(
  AiDigestNotifier.new,
);

class AiDigestNotifier extends AsyncNotifier<String?> {
  static const int _maxItems = 30;

  @override
  Future<String?> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_cacheKey(ref.read(clockProvider)()));
  }

  /*
  *生成今日日报。已有当日缓存时直接复用(除非 [force])。
  */
  Future<void> generate({bool force = false}) async {
    final config = ref.read(aiDigestConfigControllerProvider);
    if (!config.configured) {
      return;
    }
    final now = ref.read(clockProvider)();
    final prefs = ref.read(sharedPreferencesProvider);
    if (!force) {
      final cached = prefs.getString(_cacheKey(now));
      if (cached != null && cached.isNotEmpty) {
        state = AsyncData(cached);
        return;
      }
    }
    state = const AsyncLoading();
    try {
      final items = await _todayItems(now);
      final text = await ref.read(aiDigestLlmClientProvider).complete(
            baseUrl: config.baseUrl,
            apiKey: config.apiKey!,
            model: config.model,
            systemPrompt: _systemPrompt,
            userPrompt: _buildUserPrompt(items, now),
          );
      await prefs.setString(_cacheKey(now), text);
      state = AsyncData(text);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<AiNewsItem>> _todayItems(DateTime now) async {
    final all = await ref.read(aiNewsCacheDaoProvider).readAll();
    final today = DateTime(now.year, now.month, now.day);
    final items = [
      for (final item in all)
        if (!item.publishedAt.toLocal().isBefore(today)) item,
    ];
    // 今天还没有条目时(如清晨),退回最近条目,日报仍然可用。
    final picked = items.isNotEmpty ? items : all;
    return picked.length <= _maxItems ? picked : picked.sublist(0, _maxItems);
  }

  static String _cacheKey(DateTime now) {
    final local = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'ai_digest:${local.year}-${two(local.month)}-${two(local.day)}';
  }

  static const String _systemPrompt = '你是资深 AI 行业编辑。基于给定的资讯条目写一份简洁的中文日报:'
      '先用一句话概括今天的整体动向;然后列出 3-6 条最值得关注的要点,'
      '每条一行、以「- 」开头、给出为什么重要;只依据给定条目,不要编造。';

  static String _buildUserPrompt(List<AiNewsItem> items, DateTime now) {
    final local = now.toLocal();
    final buf = StringBuffer('日期:${local.year}-${local.month}-${local.day}\n条目:\n');
    for (final item in items) {
      final title = item.title.isNotEmpty ? item.title : item.titleEn;
      buf.writeln('- [${item.category.label}] $title(${item.source})');
      if (item.summary.isNotEmpty) {
        final s = item.summary;
        buf.writeln('  摘要:${s.length > 120 ? s.substring(0, 120) : s}');
      }
    }
    return buf.toString();
  }
}
