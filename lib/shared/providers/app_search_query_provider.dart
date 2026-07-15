import 'package:flutter_riverpod/flutter_riverpod.dart';

// 深度报告 / 项目页顶部搜索关键词,跨 feature 共享。
// repo_detail、home 也会写入以跳转至项目搜索结果。
// 空字符串表示不过滤当前报告数据。
final projectSearchQueryProvider = StateProvider<String>((ref) => '');
