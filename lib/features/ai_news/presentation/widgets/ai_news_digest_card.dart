import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/ai_digest_config_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/ai_digest_providers.dart';
import 'ai_digest_settings_dialog.dart';

/*
*今日 AI 日报卡片(列表页顶部)。
*- 未配置 Key:只显示引导与「配置」入口,不发任何请求
*- 已配置:生成 / 展示当日缓存 / 明确报错,不伪造内容
*/
class AiNewsDigestCard extends ConsumerWidget {
  const AiNewsDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(aiDigestConfigControllerProvider);
    final digest = ref.watch(aiDigestNotifierProvider);
    final colors = Theme.of(context).colorScheme;
    if (Breakpoints.isCompact(context)) {
      return _CompactDigestBanner(config: config, digest: digest);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l10n.tr('ai_news.digest_title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface))),
                if (config.configured && digest.valueOrNull != null)
                  IconButton(
                    tooltip: l10n.tr('ai_news.digest_regenerate'),
                    iconSize: 18,
                    onPressed: digest.isLoading ? null : () => ref.read(aiDigestNotifierProvider.notifier).generate(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                IconButton(
                  tooltip: l10n.tr('ai_news.digest_settings'),
                  iconSize: 18,
                  onPressed: () => showDialog<void>(context: context, builder: (_) => const AiDigestSettingsDialog()),
                  icon: const Icon(Icons.settings_outlined),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _DigestBody(config: config, digest: digest)
          ],
        ),
      ),
    );
  }
}

/*
*移动端日报横幅:使用设计稿同款浅青插画背景和紧凑操作层级。
*/
class _CompactDigestBanner extends ConsumerWidget {
  const _CompactDigestBanner({required this.config, required this.digest});

  // 日报安全配置状态。
  final AiDigestConfigState config;

  // 当日日报异步内容。
  final AsyncValue<String?> digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(AppRadius.xl);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          image: const DecorationImage(image: AssetImage('assets/ai_news/digest_banner.png'), fit: BoxFit.cover),
          borderRadius: radius,
          border: Border.all(color: isLight ? AppColors.borderLight : colors.outlineVariant),
          boxShadow: [if (isLight) BoxShadow(color: AppColors.brand.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, 120, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 20, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.tr('ai_news.digest_title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  _CompactDigestBody(config: config, digest: digest),
                ],
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: colors.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                elevation: isLight ? 1 : 0,
                child: IconButton(
                  tooltip: l10n.tr('ai_news.digest_settings'),
                  onPressed: () => showDialog<void>(context: context, builder: (_) => const AiDigestSettingsDialog()),
                  icon: Icon(Icons.settings_outlined, size: 19, color: colors.onSurfaceVariant),
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
*移动端日报内容状态:在横幅有限高度内保留配置、生成、重试主路径。
*/
class _CompactDigestBody extends ConsumerWidget {
  const _CompactDigestBody({required this.config, required this.digest});

  // 日报安全配置状态。
  final AiDigestConfigState config;

  // 当日日报异步内容。
  final AsyncValue<String?> digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!config.configured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('ai_news.digest_unconfigured'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: () => showDialog<void>(context: context, builder: (_) => const AiDigestSettingsDialog()),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.tr('ai_news.digest_configure')),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (digest.isLoading) {
      return const SizedBox(height: 48, child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator(strokeWidth: 2.4)));
    }
    if (digest.hasError) {
      return Row(
        children: [
          Expanded(
            child: Text(l10n.tr('ai_news.digest_failed'), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(color: colors.error)),
          ),
          TextButton(onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(force: true), child: Text(l10n.tr('common.retry'))),
        ],
      );
    }
    final text = digest.valueOrNull;
    if (text == null || text.isEmpty) {
      return SizedBox(
        height: 40,
        child: FilledButton.tonalIcon(
          onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: Text(l10n.tr('ai_news.digest_generate')),
        ),
      );
    }
    return Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(color: colors.onSurface, height: 1.5));
  }
}

class _DigestBody extends ConsumerWidget {
  const _DigestBody({required this.config, required this.digest});

  final AiDigestConfigState config;
  final AsyncValue<String?> digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!config.configured) {
      // 未配置态收成单行:一句引导 + 配置入口;安全说明挪进配置对话框。
      return Row(children: [
        Expanded(
          child: Text(
            l10n.tr('ai_news.digest_unconfigured'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => showDialog<void>(context: context, builder: (_) => const AiDigestSettingsDialog()),
          child: Text(l10n.tr('ai_news.digest_configure')),
        ),
      ]);
    }
    if (digest.isLoading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Center(child: CircularProgressIndicator()));
    }
    if (digest.hasError) {
      final kind = digest.error!.asAppException().kind.name;
      return Row(
        children: [
          Expanded(child: Text('${l10n.tr('ai_news.digest_failed')} ($kind)', style: AppTypography.bodyMedium.copyWith(color: colors.error))),
          TextButton(onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(force: true), child: Text(l10n.tr('common.retry')))
        ],
      );
    }
    final text = digest.valueOrNull;
    if (text == null || text.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: () => ref.read(aiDigestNotifierProvider.notifier).generate(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: Text(l10n.tr('ai_news.digest_generate')),
        ),
      );
    }
    return SelectableText(text, style: AppTypography.bodyMedium.copyWith(color: colors.onSurface, height: 1.6));
  }
}
