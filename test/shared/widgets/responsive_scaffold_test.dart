import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/responsive_scaffold.dart';

void main() {
  test('移动端 AI 二级页脱离底部五项导航', () {
    expect(isMobileFullScreenLocation('/ai_news/reminders'), isTrue);
    expect(isMobileFullScreenLocation('/ai_news/detail/item-id'), isTrue);
    expect(isMobileFullScreenLocation('/ai_news/detail/encoded%2Fitem'), isTrue);
    expect(isMobileFullScreenLocation('/ai_news'), isFalse);
    expect(isMobileFullScreenLocation('/discover'), isFalse);
  });
}
