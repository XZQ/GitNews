/* 文件大小格式化扩展。 */
/*  */
/* 与设置页、缓存管理面板配合:把 `File.lengthSync()` 返回的字节数 */
/* 转为人类可读的 `12.3 MB` / `1.05 GB` 文本。 */
extension FileSizeFormat on int {
  /* 字节数 → 人类可读字符串,二进制单位(1024 进制),保留 1 位小数。 */
  /*  */
  /* 阈值规则:仅当数值 ≥ 1024 时才升一档,避免 `0.5 KB` 这类丑陋输出。 */
  String toHumanReadableSize() {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var bytes = toDouble();
    var i = 0;
    while (bytes >= 1024 && i < units.length - 1) {
      bytes /= 1024;
      i++;
    }
    final value = i == 0 ? bytes.toStringAsFixed(0) : bytes.toStringAsFixed(1);
    return '$value ${units[i]}';
  }
}
