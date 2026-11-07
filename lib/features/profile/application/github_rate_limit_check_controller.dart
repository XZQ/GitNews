import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/github_token_controller.dart';
import '../domain/github_rate_limit.dart';
import 'github_rate_limit_providers.dart';

/*
*「检查配额」按钮的异步业务状态。
*
*null 表示本次会话尚未检查;加载中、成功、失败都通过 AsyncValue 表达,
*不再把请求状态留在页面的 setState 里。
*/
class GitHubRateLimitCheckController extends Notifier<AsyncValue<GitHubRateLimitSnapshot>?> {
  @override
  AsyncValue<GitHubRateLimitSnapshot>? build() => null;

  /* 拉取当前 token 的配额;重复点击只接受第一次请求。 */
  Future<void> check() async {
    if (state?.isLoading ?? false) {
      return;
    }
    state = const AsyncLoading();
    try {
      final token = ref.read(githubTokenControllerProvider).token;
      state = AsyncData(await ref.read(githubRateLimitClientProvider).fetch(token: token));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  /* token 变更后旧配额不再可信,回到「尚未检查」。 */
  void reset() {
    state = null;
  }
}

final githubRateLimitCheckProvider = NotifierProvider<GitHubRateLimitCheckController, AsyncValue<GitHubRateLimitSnapshot>?>(GitHubRateLimitCheckController.new);
