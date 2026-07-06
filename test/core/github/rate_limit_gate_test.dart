import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github_news/core/github/rate_limit_gate.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('initial status is not blocked', () {
    final status = container.read(rateLimitGateProvider);
    expect(status.isBlocked, isFalse);
    expect(status.remainingSeconds, 0);
  });

  test('trigger sets blocked until future time', () {
    final controller = container.read(rateLimitGateProvider.notifier);
    controller.trigger(60);
    final status = container.read(rateLimitGateProvider);
    expect(status.isBlocked, isTrue);
    expect(status.remainingSeconds, lessThanOrEqualTo(60));
    expect(status.remainingSeconds, greaterThan(0));
    expect(status.lastRetryAfterSeconds, 60);
  });

  test('trigger clamps negative values to 1 second', () {
    final controller = container.read(rateLimitGateProvider.notifier);
    controller.trigger(-10);
    final status = container.read(rateLimitGateProvider);
    expect(status.isBlocked, isTrue);
    expect(status.lastRetryAfterSeconds, 1);
  });

  test('trigger clamps excessive values to 1 hour', () {
    final controller = container.read(rateLimitGateProvider.notifier);
    controller.trigger(99999);
    final status = container.read(rateLimitGateProvider);
    expect(status.lastRetryAfterSeconds, 3600);
  });

  test('clear resets status', () {
    final controller = container.read(rateLimitGateProvider.notifier);
    controller.trigger(60);
    controller.clear();
    final status = container.read(rateLimitGateProvider);
    expect(status.isBlocked, isFalse);
    expect(status.blockedUntil, isNull);
  });
}
