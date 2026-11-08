import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repository_feed.dart';

/*
 *「一份仓库摘要流」的注入点。
 *
 *core 不认识任何 feature,所以这里只声明契约、不提供实现;具体实现(如 trending 的
 *feed 适配器)由组合根在 `lib/app/di/app_overrides.dart` 里 override。缺省实现直接
 *抛错,避免忘记装配时静默拿到空数据。
 */
final repositoryFeedProvider = Provider<RepositoryFeed>((ref) => throw StateError('repositoryFeedProvider must be overridden by the composition root'));
