/// 数据口径标记。
///
/// 无服务端阶段同一张卡片里可能同时存在真实 GitHub 字段和本地估算曲线,
/// 用显式枚举避免把估算值误展示成真实历史。
enum DataProvenance {
  /// 直接来自远端 API 或本地快照观测值。
  observed,

  /// 基于当前观测值推导的代理指标或展示曲线。
  estimated,

  /// 远端不可用时使用的本地种子/演示数据。
  localFallback;

  static DataProvenance fromName(String? name) {
    return DataProvenance.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DataProvenance.localFallback,
    );
  }

  String get zhLabel {
    return switch (this) {
      DataProvenance.observed => '真实观测',
      DataProvenance.estimated => '估算口径',
      DataProvenance.localFallback => '本地兜底',
    };
  }
}
