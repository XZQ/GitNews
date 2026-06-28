import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_trending_repository.dart';
import '../domain/trending_repository.dart';

final trendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return const LocalTrendingRepository();
});

final trendingDigestProvider = FutureProvider<TrendingDigest>((ref) {
  return ref.watch(trendingRepositoryProvider).getDigest();
});
