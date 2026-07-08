import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/tech_hotspot_models.dart';
import 'tech_hotspot_providers.dart';

// 单个技术主题详情。未找到时抛 [AppExceptionKind.notFound]。
final techHotspotDetailProvider = FutureProvider.family<TechTopic, String>((
  ref,
  id,
) async {
  final topic = await ref.watch(techHotspotRepositoryProvider).getById(id);
  if (topic == null) {
    throw const AppException(kind: AppExceptionKind.notFound);
  }
  return topic;
});

// 与当前主题相关的其它主题(取前 3 条,排除自身)。
final techHotspotRelatedProvider =
    FutureProvider.family<List<TechTopic>, String>((ref, id) async {
  final all = await ref.watch(techHotspotRepositoryProvider).allTopics();
  return all.where((e) => e.id != id).take(3).toList();
});
