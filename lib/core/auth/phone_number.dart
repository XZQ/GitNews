/* 把中国大陆手机号规范化为 E.164；格式无效时返回 null。 */
String? normalizeMainlandPhoneNumber(String input) {
  var value = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (value.startsWith('+86')) {
    value = value.substring(3);
  } else if (value.startsWith('0086')) {
    value = value.substring(4);
  }
  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
    return null;
  }
  return '+86$value';
}

/* 把 E.164 中国大陆手机号转换为适合用户确认的脱敏文本。 */
String maskMainlandPhoneNumber(String? phone) {
  final normalized = phone == null ? null : normalizeMainlandPhoneNumber(phone);
  if (normalized == null) {
    return '';
  }
  final local = normalized.substring(3);
  return '+86 ${local.substring(0, 3)}****${local.substring(7)}';
}

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
