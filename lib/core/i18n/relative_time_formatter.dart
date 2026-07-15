import 'app_localizations.dart';

String formatRelativeTime(AppLocalizations l10n, DateTime occurredAt, {DateTime? now}) {
  final localTime = occurredAt.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final difference = current.difference(localTime);
  if (difference.isNegative || difference.inMinutes < 1) {
    return l10n.tr('time.just_now');
  }
  if (difference.inHours < 1) {
    return l10n.tr('time.minutes_ago').replaceAll('{n}', '${difference.inMinutes}');
  }
  if (difference.inDays < 1) {
    return l10n.tr('time.hours_ago').replaceAll('{n}', '${difference.inHours}');
  }
  if (difference.inDays < 7) {
    return l10n.tr('time.days_ago').replaceAll('{n}', '${difference.inDays}');
  }
  String two(int value) => value.toString().padLeft(2, '0');
  return '${localTime.year}-${two(localTime.month)}-${two(localTime.day)}';
}
