import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../application/ai_news_library_providers.dart';
import '../../application/ai_news_providers.dart';
import '../../domain/ai_news_library_filter.dart';

Future<void> showAiNewsLibraryFiltersDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AiNewsLibraryFiltersDialog(),
  );
}

class AiNewsLibraryFiltersDialog extends ConsumerStatefulWidget {
  const AiNewsLibraryFiltersDialog({super.key});

  @override
  ConsumerState<AiNewsLibraryFiltersDialog> createState() => _AiNewsLibraryFiltersDialogState();
}

class _AiNewsLibraryFiltersDialogState extends ConsumerState<AiNewsLibraryFiltersDialog> {
  String? _source;
  int? _days;
  AiNewsReadFilter _read = AiNewsReadFilter.all;

  @override
  void initState() {
    super.initState();
    final current = ref.read(aiNewsLibraryFilterProvider);
    _source = current.source;
    _read = current.read;
    final after = current.publishedAfter;
    if (after != null) {
      final days = ref.read(clockProvider)().difference(after).inDays;
      _days = days <= 7 ? 7 : 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sources = ref.watch(aiNewsLibrarySourcesProvider).valueOrNull ?? const [];
    return AlertDialog(
      title: Text(l10n.tr('ai_news.filters.title')),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _source ?? '',
              decoration: InputDecoration(
                labelText: l10n.tr('ai_news.filters.source'),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.tr('ai_news.filters.all_sources')),
                ),
                for (final source in sources) DropdownMenuItem(value: source, child: Text(source)),
              ],
              onChanged: (value) => setState(
                () => _source = value == null || value.isEmpty ? null : value,
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.tr('ai_news.filters.time')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final days in <int?>[null, 7, 30])
                  ChoiceChip(
                    label: Text(
                      days == null ? l10n.tr('ai_news.filters.all_time') : l10n.tr('ai_news.filters.last_days').replaceAll('{days}', '$days'),
                    ),
                    selected: _days == days,
                    onSelected: (_) => setState(() => _days = days),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.tr('ai_news.filters.read_state')),
            const SizedBox(height: 8),
            SegmentedButton<AiNewsReadFilter>(
              segments: [
                ButtonSegment(
                  value: AiNewsReadFilter.all,
                  label: Text(l10n.tr('ai_news.filters.read_all')),
                ),
                ButtonSegment(
                  value: AiNewsReadFilter.unread,
                  label: Text(l10n.tr('ai_news.filters.unread')),
                ),
                ButtonSegment(
                  value: AiNewsReadFilter.read,
                  label: Text(l10n.tr('ai_news.filters.read')),
                ),
              ],
              selected: {_read},
              onSelectionChanged: (value) => setState(() => _read = value.single),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: Text(l10n.tr('common.reset'))),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tr('common.cancel')),
        ),
        FilledButton(onPressed: _apply, child: Text(l10n.tr('common.confirm'))),
      ],
    );
  }

  void _reset() {
    ref.read(aiNewsLibraryFilterProvider.notifier).state = const AiNewsLibraryFilter();
    Navigator.of(context).pop();
  }

  void _apply() {
    final now = ref.read(clockProvider)();
    ref.read(aiNewsLibraryFilterProvider.notifier).state = AiNewsLibraryFilter(
      source: _source,
      publishedAfter: _days == null ? null : now.subtract(Duration(days: _days!)),
      read: _read,
    );
    Navigator.of(context).pop();
  }
}
