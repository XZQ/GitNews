/// 间距 token(8dp 基准 + 半步长过渡值)。
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 半步长 token:用于设计稿里介于 xs(4) 和 sm(8) 之间、或 sm(8) 和
  /// md(12) 之间的细微间距(常见于 chips、icon gaps)。新增页面优先用这些
  /// 而不是裸值,避免 5/6/10/14 之类散落魔法数。
  static const double xs2 = 6; // 介于 xs 与 sm 之间
  static const double sm2 = 10; // 介于 sm 与 md 之间
  static const double md2 = 14; // 介于 md 与 lg 之间
  static const double lg2 = 20; // 介于 lg 与 xl 之间
  static const double xl2 = 28; // 介于 xl 与 xxl 之间

  // 列表项
  static const double listItemMinHeight = 72;
  static const double listItemGap = 8;
}
