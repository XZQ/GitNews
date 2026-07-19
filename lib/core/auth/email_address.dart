/* 把邮箱地址转换为不泄露完整标识的展示文本。 */
String maskEmailAddress(String? email) {
  final value = email?.trim();
  if (value == null || value.isEmpty || !value.contains('@')) {
    return '';
  }
  final parts = value.split('@');
  if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
    return '';
  }
  final local = parts.first;
  final visible = local.length <= 2 ? local.substring(0, 1) : local.substring(0, 2);
  return '$visible***@${parts.last}';
}
