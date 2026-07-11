import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/strings_en_us.dart';
import 'package:github_news/core/i18n/strings_zh_cn.dart';

void main() {
  test('Chinese and English localization keys stay symmetric', () {
    expect(stringsZhCN.keys.toSet(), stringsEnUS.keys.toSet());
  });
}
