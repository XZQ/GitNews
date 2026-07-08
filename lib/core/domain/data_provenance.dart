/* 
*数据口径标记。
*无服务端阶段同一张卡片里可能同时存在真实 GitHub 字段和本地估算曲线,
*用显式枚举避免把估算值误展示成真实历史。
*
*状态码(5 态):
*- [live]       实时来自远端 API。
*- [freshCache] 来自本地缓存且仍在 TTL 内(新鲜缓存)。
*- [staleCache] 来自本地缓存但已过期,仅作为兜底展示(陈旧缓存)。
*- [estimated]  基于当前观测值推导的代理指标或展示曲线。
*- [seed]       远端不可用时使用的本地种子/演示数据。
*/
enum DataProvenance {
  // 实时来自远端 API 或本地快照观测值。
  live,

  // 来自本地缓存且仍在 TTL 内(新鲜缓存)。
  freshCache,

  // 来自本地缓存但已过期,仅作为兜底展示(陈旧缓存)。
  staleCache,

  // 基于当前观测值推导的代理指标或展示曲线。
  estimated,

  // 远端不可用时使用的本地种子/演示数据。
  seed;

  static DataProvenance fromName(String? name) {
    return DataProvenance.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DataProvenance.seed,
    );
  }

  /* 
  *i18n key for the full label.
  */
  String get labelKey {
    return switch (this) {
      DataProvenance.live => 'provenance.live.full',
      DataProvenance.freshCache => 'provenance.fresh_cache.full',
      DataProvenance.staleCache => 'provenance.stale_cache.full',
      DataProvenance.estimated => 'provenance.estimated.full',
      DataProvenance.seed => 'provenance.seed.full',
    };
  }

  String get zhLabel {
    return switch (this) {
      DataProvenance.live => '实时',
      DataProvenance.freshCache => '新鲜缓存',
      DataProvenance.staleCache => '陈旧缓存',
      DataProvenance.estimated => '估算口径',
      DataProvenance.seed => '本地种子',
    };
  }
}
