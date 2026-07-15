import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/* 
*GitHub 热榜数据源模式。
*/
enum TrendingDataSourceMode {
  local,
  github;

  static TrendingDataSourceMode fromName(String? value) {
    return TrendingDataSourceMode.values.firstWhere((mode) => mode.name == value, orElse: () => TrendingDataSourceMode.local);
  }
}

/* 
*GitHub 热榜数据源模式 controller。
*默认使用 [TrendingDataSourceMode.local],避免匿名 GitHub Search 触发限流。
*/
class TrendingDataSourceModeController extends Notifier<TrendingDataSourceMode> {
  static const _kKey = 'trending_data_source_mode';

  @override
  TrendingDataSourceMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return TrendingDataSourceMode.fromName(prefs.getString(_kKey));
  }

  Future<void> setMode(TrendingDataSourceMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kKey, mode.name);
  }
}

final trendingDataSourceModeControllerProvider = NotifierProvider<TrendingDataSourceModeController, TrendingDataSourceMode>(TrendingDataSourceModeController.new);
