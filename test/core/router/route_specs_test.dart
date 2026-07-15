import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/router/route_specs.dart';

void main() {
  test('compact IA exposes five destinations mapped to desktop branches', () {
    expect(mobileAppTabs.map((tab) => tab.branchIndex), [0, 1, 4, 5, 7]);
    expect(mobileDestinationIndex(0), 0);
    expect(mobileDestinationIndex(1), 1);
    expect(mobileDestinationIndex(4), 2);
    expect(mobileDestinationIndex(5), 3);
    expect(mobileDestinationIndex(7), 4);
  });

  test('compact IA collapses non-pinned branches into discover tab', () {
    for (final branch in [2, 3, 6]) {
      expect(mobileDestinationIndex(branch), 2);
    }
  });

  test('compact IA uses distinct localized labels', () {
    expect(mobileAppTabs.map((tab) => tab.labelKey).toSet(), {'mobile.today', 'mobile.ai', 'mobile.discover', 'mobile.monitor', 'mobile.settings'});
  });
}
