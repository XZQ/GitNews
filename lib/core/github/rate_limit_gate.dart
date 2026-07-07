import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/* GitHub rate limit 全局熔断状态。 */
class RateLimitGateStatus {
  const RateLimitGateStatus({
    this.blockedUntil,
    this.lastRetryAfterSeconds,
  });

  /* 触达配额后,此时间之前所有 GitHub 请求短路到 fallback。 */
  final DateTime? blockedUntil;

  /* 上次触发时记录的 retryAfter(秒),用于 UI 展示。 */
  final int? lastRetryAfterSeconds;

  bool get isBlocked {
    final until = blockedUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /* 剩余阻断秒数(向下取整);未阻断返回 0。 */
  int get remainingSeconds {
    final until = blockedUntil;
    if (until == null) return 0;
    final delta = until.difference(DateTime.now()).inSeconds;
    return delta < 0 ? 0 : delta;
  }

  static const RateLimitGateStatus empty = RateLimitGateStatus();
}

/* 全局 rate limit 熔断闸门。 */
/*  */
/* 当任一 GitHub Repository catch 到 [AppExceptionKind.rateLimit] 时, */
/* 调用 [trigger] 上报 retryAfter;此窗口内 [status] 的 isBlocked 为 true, */
/* 其它 Repository 应在调用远端前先检查 [status] 并直接走 fallback, */
/* 避免剩余配额为 0 后继续打 API 浪费请求。 */
class RateLimitGateController extends Notifier<RateLimitGateStatus> {
  Timer? _timer;

  @override
  RateLimitGateStatus build() {
    ref.onDispose(() => _timer?.cancel());
    return const RateLimitGateStatus();
  }

  /* 上报一次 rate limit 触发,设置阻断窗口。 */
  void trigger(int retryAfterSeconds) {
    final seconds = retryAfterSeconds.clamp(1, 3600);
    final until = DateTime.now().add(Duration(seconds: seconds));
    state = RateLimitGateStatus(
      blockedUntil: until,
      lastRetryAfterSeconds: seconds,
    );
    _timer?.cancel();
    _timer = Timer(Duration(seconds: seconds), () {
      state = const RateLimitGateStatus();
    });
  }

  /* 显式清除阻断(例如用户手动重试)。 */
  void clear() {
    _timer?.cancel();
    state = const RateLimitGateStatus();
  }
}

final rateLimitGateProvider =
    NotifierProvider<RateLimitGateController, RateLimitGateStatus>(
  RateLimitGateController.new,
);
