import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/monitor/domain/monitor_observation.dart';
import 'package:github_news/features/monitor/domain/monitor_rule.dart';
import 'package:github_news/features/monitor/domain/monitor_rule_evaluator.dart';

void main() {
  const evaluator = MonitorRuleEvaluator();
  const allRules = {
    MonitorRuleIds.starDailyDelta,
    MonitorRuleIds.starDailyRate,
    MonitorRuleIds.forkDailyDelta,
    MonitorRuleIds.issueHeatRatio,
  };

  test('first observation establishes a baseline without alerts', () {
    final events = evaluator.evaluate(
      previous: null,
      current: observation(day: 2),
      enabledRuleIds: allRules,
    );

    expect(events, isEmpty);
  });

  test('exact threshold values trigger all enabled rules', () {
    final events = evaluator.evaluate(
      previous: observation(
        day: 1,
        stars: 2000,
        forks: 10,
        issues: 1,
      ),
      current: observation(
        day: 2,
        stars: 2200,
        forks: 60,
        issues: 9,
      ),
      enabledRuleIds: allRules,
    );

    expect(
      events.map((event) => event.ruleId).toSet(),
      allRules,
    );
  });

  test('values below every threshold do not trigger', () {
    final events = evaluator.evaluate(
      previous: observation(
        day: 1,
        stars: 1000,
        forks: 10,
        issues: 1,
      ),
      current: observation(
        day: 2,
        stars: 1099,
        forks: 59,
        issues: 8,
      ),
      enabledRuleIds: allRules,
    );

    expect(events, isEmpty);
  });

  test('disabled rules never trigger', () {
    final events = evaluator.evaluate(
      previous: observation(day: 1, stars: 1, forks: 1, issues: 0),
      current: observation(day: 2, stars: 1000, forks: 1000, issues: 20),
      enabledRuleIds: const {MonitorRuleIds.forkDailyDelta},
    );

    expect(events, hasLength(1));
    expect(events.single.ruleId, MonitorRuleIds.forkDailyDelta);
  });

  test('same local day and negative deltas never trigger', () {
    final sameDay = evaluator.evaluate(
      previous: observation(day: 1, hour: 1),
      current: observation(day: 1, hour: 20, stars: 5000, forks: 5000),
      enabledRuleIds: allRules,
    );
    final negative = evaluator.evaluate(
      previous: observation(day: 1, stars: 5000, forks: 5000, issues: 50),
      current: observation(day: 2, stars: 1000, forks: 1000, issues: 1),
      enabledRuleIds: allRules,
    );

    expect(sameDay, isEmpty);
    expect(negative, isEmpty);
  });

  test('event id is stable for repository rule and local day', () {
    final first = evaluator.evaluate(
      previous: observation(day: 1, stars: 1000),
      current: observation(day: 2, stars: 1200, hour: 1),
      enabledRuleIds: const {MonitorRuleIds.starDailyDelta},
    );
    final second = evaluator.evaluate(
      previous: observation(day: 1, stars: 1000),
      current: observation(day: 2, stars: 1400, hour: 20),
      enabledRuleIds: const {MonitorRuleIds.starDailyDelta},
    );

    expect(first.single.id, second.single.id);
    expect(first.single.id, 'owner/repo|star_daily_delta|2026-07-02');
  });
}

MonitorObservation observation({
  int day = 1,
  int hour = 12,
  int stars = 1000,
  int forks = 10,
  int issues = 1,
}) {
  return MonitorObservation(
    repoFullName: 'owner/repo',
    stars: stars,
    forks: forks,
    openIssues: issues,
    observedAt: DateTime(2026, 7, day, hour),
  );
}
