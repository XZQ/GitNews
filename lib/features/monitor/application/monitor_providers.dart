import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_monitor_repository.dart';
import '../domain/monitor_repository.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return const LocalMonitorRepository();
});

final monitorDigestProvider = FutureProvider<MonitorDigest>((ref) {
  return ref.watch(monitorRepositoryProvider).getDigest();
});
