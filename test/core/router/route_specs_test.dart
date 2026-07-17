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

  test('compact IA maps AI Radar branch into overview tab', () {
    for (final branch in [0, 3]) {
      expect(mobileDestinationIndex(branch), 0);
    }
  });

  test('compact IA keeps pending secondary branches under current owners', () {
    expect(mobileDestinationIndex(2), 2);
    expect(mobileDestinationIndex(6), 4);
  });

  test('compact IA uses distinct localized labels', () {
    expect(mobileAppTabs.map((tab) => tab.labelKey).toSet(), {'tab.home', 'mobile.ai', 'mobile.discover', 'mobile.monitor', 'mobile.settings'});
  });
}
