import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/responsive_scaffold.dart';

void main() {
  test('移动端所有二级页脱离底部五项导航', () {
    for (final location in const [
      '/home/detail/repo',
      '/home/tech_hotspot_detail/topic',
      '/ai_news/reminders',
      '/ai_news/detail/item-id',
      '/discover/detail/repo',
      '/monitor/alerts',
      '/profile/sources',
      '/trending',
      '/tech_hotspot',
      '/project',
    ]) {
      expect(isMobileFullScreenLocation(location), isTrue, reason: location);
    }
    for (final location in const ['/home', '/ai_news', '/discover', '/monitor', '/profile']) {
      expect(isMobileFullScreenLocation(location), isFalse, reason: location);
    }
  });

  test('AI 主页面与移动端二级页由内部 AppBar 接管状态栏沉浸', () {
    expect(usesImmersiveStatusBar('/ai_news'), isTrue);
    expect(usesImmersiveStatusBar('/profile'), isTrue);
    expect(usesImmersiveStatusBar('/ai_news/reminders'), isTrue);
    expect(usesImmersiveStatusBar('/ai_news/detail/item-id'), isTrue);
    expect(usesImmersiveStatusBar('/home/detail/repo'), isTrue);
    expect(usesImmersiveStatusBar('/discover/detail/repo'), isTrue);
    expect(usesImmersiveStatusBar('/home'), isFalse);
    expect(usesImmersiveStatusBar('/discover'), isFalse);
  });

  test('移动端五个一级页面启用双击返回退出保护', () {
    for (final location in const ['/home', '/ai_news', '/discover', '/monitor', '/profile']) {
      expect(isMobilePrimaryLocation(location), isTrue, reason: location);
    }
    expect(isMobilePrimaryLocation('/ai_news/reminders'), isFalse);
    expect(isMobilePrimaryLocation('/discover/detail/repo'), isFalse);
  });
}
