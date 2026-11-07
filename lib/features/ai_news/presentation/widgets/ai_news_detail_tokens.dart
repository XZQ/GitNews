import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/* 详情页正文区域的最大宽度。 */
const double aiNewsDetailMaxWidth = 760;

/* 将资讯时间格式化为详情页使用的本地时间。 */
String formatAiNewsDetailDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

/* 返回设计稿中的二级文字色。 */
Color aiNewsDetailSecondaryColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;
}

/* 返回设计稿中的弱化文字色。 */
Color aiNewsDetailMutedColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light ? AppColors.textMutedLight : AppColors.textMutedDark;
}
