import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/* 
*通用指标卡(可显示 Star 增速 / 监控数 / 告警数 / 语言分布等)。
*/
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.subtitle,
    this.icon,
    this.accent,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final deltaColor = deltaPositive ? colors.tertiary : colors.error;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (accent ?? colors.primary).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: accent ?? colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTypography.headlineLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      deltaPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: deltaColor,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      delta!,
                      style: AppTypography.labelSmall.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: AppSpacing.xs2),
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
