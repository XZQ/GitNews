import 'data_freshness.dart';

enum RepoActivityType {
  push,
  issues,
  pullRequest,
  release,
  create,
  other,
}

class RepoActivityEvent {
  const RepoActivityEvent({
    required this.repoFullName,
    required this.type,
    required this.title,
    required this.actorLogin,
    required this.occurredAt,
    required this.htmlUrl,
    required this.basis,
  });

  final String repoFullName;
  final RepoActivityType type;
  final String title;
  final String actorLogin;
  final DateTime occurredAt;
  final String? htmlUrl;
  final MetricBasis basis;
}
