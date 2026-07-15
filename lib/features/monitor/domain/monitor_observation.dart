class MonitorObservation {
  const MonitorObservation({required this.repoFullName, required this.stars, required this.forks, required this.openIssues, required this.observedAt});

  final String repoFullName;
  final int stars;
  final int forks;
  final int openIssues;
  final DateTime observedAt;

  String get localDayKey {
    final value = observedAt.toLocal();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
