import 'dart:io';

import 'package:flutter/services.dart';

// 仓库内开源 CJK 测试字体子集，不进入应用发布资产。
const String _portableCjkFontPath = 'test/fixtures/fonts/NotoSansSC-TestSubset.ttf';

// 同一测试 isolate 内复用字体字节。
Future<Uint8List>? _portableCjkFontBytes;

/* 将仓库内字体子集注册到一个或多个测试字体族。 */
Future<void> loadPortableTestFontFamilies(Iterable<String> families) async {
  final bytes = await (_portableCjkFontBytes ??= File(_portableCjkFontPath).readAsBytes());
  for (final family in families) {
    final loader = FontLoader(family)..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  final iconLoader = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconLoader.load();
}
