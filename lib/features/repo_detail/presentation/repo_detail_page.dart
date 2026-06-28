import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/demo_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../application/repo_detail_providers.dart';
import '../domain/repo_detail_repository.dart';
import 'detail/repo_detail_activity.dart';
import 'detail/repo_detail_chart.dart';
import 'detail/repo_detail_contributors.dart';
import 'detail/repo_detail_header.dart';
import 'detail/repo_detail_sidebar.dart';
import 'detail/repo_detail_skeleton.dart';
import 'detail/repo_detail_stats.dart';

class RepoDetailPage extends ConsumerWidget {
  const RepoDetailPage({required this.fullName, super.key});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(repoDetailDigestProvider(fullName));
    return Scaffold(
      appBar: AppBar(
        title: state.maybeWhen(
          data: (digest) => Text(digest.repo.fullName),
          orElse: () => const Text('仓库详情'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: state.when(
        data: (digest) {
          if (digest.relatedRepos.isEmpty && digest.contributors.isEmpty) {
            return const EmptyView(
              icon: Icons.source_outlined,
              message: '未找到仓库详情',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Mobile(digest: digest),
            medium: (_) => CenteredContent(child: _Desktop(digest: digest)),
            expanded: (_) => CenteredContent(child: _Desktop(digest: digest)),
          );
        },
        loading: () => const RepoDetailSkeleton(),
        error: (error, stack) => ErrorView(
          error: _toAppException(error, stack),
          onRetry: () => ref.invalidate(repoDetailDigestProvider(fullName)),
        ),
      ),
    );
  }

  AppException _toAppException(Object error, StackTrace stack) {
    if (error is AppException) return error;
    return AppException(
      kind: AppExceptionKind.unknown,
      cause: error,
      stack: stack,
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.digest});

  final RepoDetailDigest digest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        RepoDetailHeader(repo: digest.repo),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailStats(
          repo: digest.repo,
          contributorCount: digest.contributors.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailChart(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailContributors(contributors: digest.contributors),
        const SizedBox(height: AppSpacing.lg),
        const RepoDetailActivity(),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({required this.digest});

  final RepoDetailDigest digest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        RepoDetailHeader(repo: digest.repo),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: _Left(digest: digest)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: _Right(relatedRepos: digest.relatedRepos),
            ),
          ],
        ),
      ],
    );
  }
}

class _Left extends StatelessWidget {
  const _Left({required this.digest});

  final RepoDetailDigest digest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepoDetailStats(
          repo: digest.repo,
          contributorCount: digest.contributors.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailChart(digest: digest),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailContributors(contributors: digest.contributors),
        const SizedBox(height: AppSpacing.lg),
        const RepoDetailActivity(),
      ],
    );
  }
}

class _Right extends StatelessWidget {
  const _Right({required this.relatedRepos});

  final List<DemoRepo> relatedRepos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RepoDetailAboutCard(),
        const SizedBox(height: AppSpacing.lg),
        const RepoDetailTopicsCard(),
        const SizedBox(height: AppSpacing.lg),
        RepoDetailRelatedReposCard(repos: relatedRepos),
      ],
    );
  }
}
