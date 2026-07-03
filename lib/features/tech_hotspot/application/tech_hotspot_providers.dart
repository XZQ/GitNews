import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_tech_hotspot_repository.dart';
import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';

final techHotspotRepositoryProvider = Provider<TechHotspotRepository>((ref) {
  return const LocalTechHotspotRepository();
});

final techHotspotDigestProvider = FutureProvider<TechHotspotDigest>((ref) {
  return ref.watch(techHotspotRepositoryProvider).getDigest();
});
