import 'package:flutter/widgets.dart';

/// Material 3 三档断点。
enum FormFactor { compact, medium, expanded }

/// `compact`(< 600)手机、`medium`(600–1024)平板、`expanded`(≥ 1024)桌面。
class Breakpoints {
  const Breakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 1024;

  static FormFactor of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactMax) return FormFactor.compact;
    if (width < mediumMax) return FormFactor.medium;
    return FormFactor.expanded;
  }

  static bool isCompact(BuildContext c) => of(c) == FormFactor.compact;
  static bool isMedium(BuildContext c) => of(c) == FormFactor.medium;
  static bool isExpanded(BuildContext c) => of(c) == FormFactor.expanded;
}
