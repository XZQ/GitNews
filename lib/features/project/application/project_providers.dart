import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../trending/application/trending_providers.dart';

/// 项目深度报告页(探索 / 发现 / 活动)共用的摘要。
class ProjectDigest {
  const ProjectDigest({
    required this.repos,
    required this.contributors,
    required this.primaryTrend,
    required this.secondaryTrend,
  });

  final List<DemoRepo> repos;
  final List<DemoContributor> contributors;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;

  bool get isEmpty => repos.isEmpty && contributors.isEmpty;
}

final projectDigestProvider = FutureProvider<ProjectDigest>((ref) async {
  try {
    final trending = await ref.watch(trendingRepositoryProvider).getDigest();
    return ProjectDigest(
      repos: trending.allRepos,
      contributors: DemoData.contributors,
      primaryTrend: trending.primaryTrend,
      secondaryTrend: trending.secondaryTrend,
    );
  } on AppException {
    rethrow;
  } catch (error, stack) {
    throw AppException(
      kind: AppExceptionKind.unknown,
      cause: error,
      stack: stack,
    );
  }
});
