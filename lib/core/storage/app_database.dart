/// 应用数据库占位。MVP 阶段先不引入 drift,后续需要时再加。
class AppDatabase {
  AppDatabase();

  Future<void> close() async {}

  // TODO(m2): 引入 drift + 生成表
}
