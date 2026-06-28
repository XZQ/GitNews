import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/ai_news_item.dart';

class AiNewsDetailSourceLink extends StatelessWidget {
  const AiNewsDetailSourceLink({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.sourceUrl;
    if (url == null) return const SizedBox.shrink();
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.brand),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '原文链接',
                  style: AppTypography.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.tonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制链接')),
                );
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }
}
