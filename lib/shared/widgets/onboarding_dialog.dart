import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_radius.dart';
import 'package:github_news/core/theme/app_spacing.dart';
import 'package:github_news/core/theme/app_typography.dart';

// Onboarding 完成标志的 SharedPreferences key。
const String kOnboardingCompletedKey = 'onboarding_completed';

// 是否需要显示 Onboarding。
final shouldShowOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  return !(prefs.getBool(kOnboardingCompletedKey) ?? false);
});

/* 
*标记 Onboarding 已完成。
*/
Future<void> markOnboardingCompleted(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool(kOnboardingCompletedKey, true);
}

/* 
*首次启动引导对话框。
*4 步：欢迎 → AI 动态 → GitHub 热榜 → 仓库监控 → 完成。
*/
class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  int _step = 0;

  static const _steps = [
    _OnboardingStep(icon: Icons.insights_rounded, color: AppColors.brand),
    _OnboardingStep(icon: Icons.auto_awesome_rounded, color: AppColors.brand),
    _OnboardingStep(icon: Icons.local_fire_department_rounded, color: AppColors.warning),
    _OnboardingStep(icon: Icons.notifications_rounded, color: AppColors.info)
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Dialog(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // 进度指示器
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < _steps.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xs),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: i <= _step ? step.color : colors.outlineVariant, shape: BoxShape.circle))
                    ]
                  ]),
                  const SizedBox(height: AppSpacing.xxl),
                  // 图标
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: step.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.xl)),
                    child: Icon(step.icon, size: 36, color: step.color),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // 标题
                  Text(l10n.tr(_stepKeys[_step * 2]), style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  // 描述
                  Text(l10n.tr(_stepKeys[_step * 2 + 1]), style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxl),
                  // 按钮
                  Row(children: [
                    if (!isLast) TextButton(onPressed: () => _finish(context), child: Text(l10n.tr('onboarding.skip'))) else const Spacer(),
                    const Spacer(),
                    FilledButton(
                        onPressed: () {
                          if (isLast) {
                            _finish(context);
                          } else {
                            setState(() => _step++);
                          }
                        },
                        child: Text(isLast ? l10n.tr('onboarding.done') : l10n.tr('onboarding.next')))
                  ])
                ]))));
  }

  static const _stepKeys = [
    'onboarding.welcome_title',
    'onboarding.welcome_desc',
    'onboarding.step1_title',
    'onboarding.step1_desc',
    'onboarding.step2_title',
    'onboarding.step2_desc',
    'onboarding.step3_title',
    'onboarding.step3_desc'
  ];

  Future<void> _finish(BuildContext context) async {
    await markOnboardingCompleted(ref);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _OnboardingStep {
  const _OnboardingStep({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
