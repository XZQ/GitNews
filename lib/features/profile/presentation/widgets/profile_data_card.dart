import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/file_size.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

/// 「数据与缓存」卡:展示真实 DB 文件大小并提供一键清理。
class ProfileDataCard extends ConsumerStatefulWidget {
  const ProfileDataCard({super.key});

  @override
  ConsumerState<ProfileDataCard> createState() => _ProfileDataCardState();
}

class _ProfileDataCardState extends ConsumerState<ProfileDataCard> {
  int? _bytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  void _refreshSize() {
    final reporter = ref.read(storageSizeReporterProvider);
    setState(() => _bytes = reporter.currentBytes());
  }

  Future<void> _onClear() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    final l10n = AppLocalizations.of(context);
    final reporter = ref.read(storageSizeReporterProvider);
    final before = _bytes ?? reporter.currentBytes();
    try {
      await reporter.clearAll();
      if (!mounted) return;
      setState(() => _bytes = reporter.currentBytes());
      final freed = before - (_bytes ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n
                .tr('profile.data.cleared')
                .replaceAll('{size}', freed.toHumanReadableSize()),
          ),
        ),
      );
    } catch (e) {
      AppLogger.warn('clearAll', meta: {'error': e.runtimeType.toString()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('profile.data.clear_failed'))),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sizeText = (_bytes ?? 0).toHumanReadableSize();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.data.title'),
            subtitle: l10n.tr('profile.data.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDataRow(
            label: l10n.tr('profile.data.db_size'),
            value: sizeText,
          ),
          ProfileDataRow(
            label: l10n.tr('profile.data.cap'),
            value: l10n.tr('profile.data.cap.value'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearing ? null : _onClear,
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: Text(
                _clearing
                    ? l10n.tr('profile.data.clearing')
                    : l10n.tr('profile.data.clear'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
