/* 
*圆角 token。
*/
class AppRadius {
  const AppRadius._();

  static const double dot = 2;
  static const double bar = 3;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;

  // 卡片外框:主容器圆角。工具风基线收敛到 10,比 lg(12) 更利落。
  static const double card = 10;

  static const double xl = 16;
  static const double pill = 999;
}
