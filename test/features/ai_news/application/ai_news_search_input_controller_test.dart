import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_search_input_controller.dart';

/*
*搜索输入防抖控制器:键入间歇提交,提交/清空立即生效,重复值不重复触发。
*/
void main() {
  test('键入防抖:间歇后才提交,连续输入只提交最后一次', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(aiNewsSearchInputControllerProvider);

    controller.update('op');
    // 未到 250ms 间歇即继续输入,前缀不应单独提交。
    await Future<void>.delayed(const Duration(milliseconds: 120));
    controller.update('openai');
    expect(container.read(aiNewsSearchDraftProvider), 'openai');
    expect(container.read(aiNewsSearchQueryProvider), '');

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(container.read(aiNewsSearchQueryProvider), 'openai');
  });

  test('回车提交与清空跳过防抖立即生效', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(aiNewsSearchInputControllerProvider);

    controller.update('agent', immediate: true);
    expect(container.read(aiNewsSearchDraftProvider), 'agent');
    expect(container.read(aiNewsSearchQueryProvider), 'agent');

    controller.update('');
    expect(container.read(aiNewsSearchDraftProvider), '');
    expect(container.read(aiNewsSearchQueryProvider), '');
  });

  test('外部查询写入会同步搜索框草稿', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(aiNewsSearchDraftProvider), '');
    container.read(aiNewsSearchQueryProvider.notifier).state = 'route-query';

    expect(container.read(aiNewsSearchDraftProvider), 'route-query');
  });

  test('与当前关键词相同的输入不重复提交', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(aiNewsSearchInputControllerProvider);

    controller.update('agent', immediate: true);
    var notifications = 0;
    container.listen(aiNewsSearchQueryProvider, (_, _) => notifications++);

    controller.update('agent');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(notifications, 0);
    expect(container.read(aiNewsSearchQueryProvider), 'agent');
  });

  test('新的防抖输入会取消旧的未提交值', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(aiNewsSearchInputControllerProvider);

    controller.update('rag');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    controller.update('mcp', immediate: true);
    // 旧防抖任务已被取消,间歇后不应覆盖立即提交的值。
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(container.read(aiNewsSearchQueryProvider), 'mcp');
  });
}
