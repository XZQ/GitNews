import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/router/route_specs.dart';

void main() {
  test('compact IA maps eight desktop branches into four destinations', () {
    expect(mobileAppTabs.map((tab) => tab.branchIndex), [0, 1, 2, 7]);
    expect(mobileDestinationIndex(0), 0);
    expect(mobileDestinationIndex(1), 1);
    for (final branch in [2, 3, 4, 5, 6]) {
      expect(mobileDestinationIndex(branch), 2);
    }
    expect(mobileDestinationIndex(7), 3);
  });

  test('compact IA uses distinct localized labels', () {
    expect(mobileAppTabs.map((tab) => tab.labelKey).toSet(), {'mobile.today', 'mobile.ai', 'mobile.project', 'mobile.settings'});
  });
}
