import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ai_news_sources_config.dart';
import '../di/providers.dart';

const String aiNewsSourcesPreferenceKey = 'ai_news_sources_v1';

/*
*AI 资讯源健康状态。
*
*仅记录连续失败次数和最近成功/失败时间,不保存响应正文或凭据。
*/
class AiNewsSourceHealth {
  const AiNewsSourceHealth({this.consecutiveFailures = 0, this.lastSuccessAt, this.lastFailureAt, this.lastError});

  // 连续失败次数;成功后归零。
  final int consecutiveFailures;

  // 最近成功时间(UTC)。
  final DateTime? lastSuccessAt;

  // 最近失败时间(UTC)。
  final DateTime? lastFailureAt;

  // 最近错误类型,不记录可能含敏感信息的完整错误文本。
  final String? lastError;

  bool get isDegraded => consecutiveFailures >= 3;

  AiNewsSourceHealth copyWith({int? consecutiveFailures, DateTime? lastSuccessAt, DateTime? lastFailureAt, String? lastError, bool clearError = false}) {
    return AiNewsSourceHealth(
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/*
*可管理的 AI 资讯源条目。
*/
class AiNewsSourceEntry {
  const AiNewsSourceEntry({required this.config, required this.enabled, required this.isCustom, this.health = const AiNewsSourceHealth()});

  // RSS/Atom 源配置。
  final AiNewsSourceConfig config;

  // 是否参与聚合。
  final bool enabled;

  // true 表示用户创建,允许删除。
  final bool isCustom;

  // 最近抓取健康状态。
  final AiNewsSourceHealth health;

  AiNewsSourceEntry copyWith({AiNewsSourceConfig? config, bool? enabled, AiNewsSourceHealth? health}) {
    return AiNewsSourceEntry(config: config ?? this.config, enabled: enabled ?? this.enabled, isCustom: isCustom, health: health ?? this.health);
  }
}

/*
*AI 资讯源集合状态。
*/
class AiNewsSourceState {
  const AiNewsSourceState(this.entries);

  // 内置源优先、随后是自定义源的稳定列表。
  final List<AiNewsSourceEntry> entries;

  List<AiNewsSourceConfig> get enabledConfigs => [
        for (final entry in entries)
          if (entry.enabled) entry.config
      ];

  int get enabledCount => entries.where((entry) => entry.enabled).length;

  int get degradedCount => entries.where((entry) => entry.enabled && entry.health.isDegraded).length;
}

/*
*AI 资讯源偏好控制器。
*
*内置源始终从代码配置补齐,持久化文档只覆盖启用状态、健康状态与
*用户自定义源;损坏文档会安全回退到全部内置源启用。
*/
class AiNewsSourceController extends Notifier<AiNewsSourceState> {
  @override
  AiNewsSourceState build() {
    final raw = ref.read(sharedPreferencesProvider).getString(aiNewsSourcesPreferenceKey);
    return AiNewsSourceState(_decodeEntries(raw));
  }

  /* 切换指定源的启用状态。 */
  Future<void> setEnabled(String id, bool enabled) async {
    state = AiNewsSourceState([
      for (final entry in state.entries)
        if (entry.config.id == id) entry.copyWith(enabled: enabled) else entry
    ]);
    await _persist();
  }

  /* 新增一个经过校验的自定义 RSS/Atom 源。 */
  Future<void> addCustom({required String name, required String feedUrl, required String categoryCode}) async {
    final normalizedName = name.trim();
    final normalizedUrl = _normalizeUrl(feedUrl);
    if (normalizedName.isEmpty || normalizedName.length > 80) {
      throw const FormatException('Source name must contain 1-80 characters');
    }
    if (!AiNewsSourcesConfig.supportedCategoryCodes.contains(categoryCode)) {
      throw const FormatException('Unsupported source category');
    }
    if (state.entries.any((entry) => entry.config.feedUrl.toLowerCase() == normalizedUrl.toLowerCase())) {
      throw const FormatException('Source URL already exists');
    }
    final entry = AiNewsSourceEntry(
      config: AiNewsSourceConfig(id: _customId(normalizedUrl), name: normalizedName, feedUrl: normalizedUrl, categoryCode: categoryCode),
      enabled: true,
      isCustom: true,
    );
    state = AiNewsSourceState([...state.entries, entry]);
    await _persist();
  }

  /* 删除用户自定义源;内置源不可删除。 */
  Future<void> removeCustom(String id) async {
    final target = state.entries.where((entry) => entry.config.id == id).firstOrNull;
    if (target == null || !target.isCustom) {
      return;
    }
    state = AiNewsSourceState([
      for (final entry in state.entries)
        if (entry.config.id != id) entry
    ]);
    await _persist();
  }

  /* 恢复全部内置源启用并移除自定义源。 */
  Future<void> restoreDefaults() async {
    state = AiNewsSourceState([for (final config in AiNewsSourcesConfig.sources) AiNewsSourceEntry(config: config, enabled: true, isCustom: false)]);
    await _persist();
  }

  /* 记录一次源抓取成功。 */
  Future<void> reportSuccess(String id, DateTime at) async {
    final now = at.toUtc();
    state = AiNewsSourceState([
      for (final entry in state.entries)
        if (entry.config.id == id) entry.copyWith(health: entry.health.copyWith(consecutiveFailures: 0, lastSuccessAt: now, clearError: true)) else entry,
    ]);
    await _persist();
  }

  /* 记录一次源抓取失败,只保存错误类型。 */
  Future<void> reportFailure(String id, DateTime at, Object error) async {
    final now = at.toUtc();
    state = AiNewsSourceState([
      for (final entry in state.entries)
        if (entry.config.id == id)
          entry.copyWith(
            health: entry.health.copyWith(
              consecutiveFailures: entry.health.consecutiveFailures + 1,
              lastFailureAt: now,
              lastError: error.runtimeType.toString(),
            ),
          )
        else
          entry,
    ]);
    await _persist();
  }

  Future<void> _persist() async {
    await ref.read(sharedPreferencesProvider).setString(aiNewsSourcesPreferenceKey, encodeAiNewsSourceEntries(state.entries));
  }
}

final aiNewsSourceControllerProvider = NotifierProvider<AiNewsSourceController, AiNewsSourceState>(AiNewsSourceController.new);

/* 将源条目编码为配置导出可携带的 JSON 字符串。 */
String encodeAiNewsSourceEntries(List<AiNewsSourceEntry> entries) {
  return jsonEncode([
    for (final entry in entries)
      {
        'id': entry.config.id,
        'name': entry.config.name,
        'feedUrl': entry.config.feedUrl,
        'categoryCode': entry.config.categoryCode,
        'enabled': entry.enabled,
        'isCustom': entry.isCustom,
        'consecutiveFailures': entry.health.consecutiveFailures,
        'lastSuccessAt': entry.health.lastSuccessAt?.toUtc().toIso8601String(),
        'lastFailureAt': entry.health.lastFailureAt?.toUtc().toIso8601String(),
        'lastError': entry.health.lastError,
      },
  ]);
}

/* 校验配置导入中的资讯源 JSON,返回规范化后的原文。 */
String validateAiNewsSourcesPreference(Object? raw) {
  if (raw is! String) {
    throw const FormatException('AI news sources must be a JSON string');
  }
  final decoded = _decodeStored(raw, strict: true);
  if (decoded == null) {
    throw const FormatException('Invalid AI news sources document');
  }
  return encodeAiNewsSourceEntries(decoded);
}

List<AiNewsSourceEntry> _decodeEntries(String? raw) {
  final stored = _decodeStored(raw, strict: false) ?? const <AiNewsSourceEntry>[];
  final byId = {for (final entry in stored) entry.config.id: entry};
  final result = <AiNewsSourceEntry>[
    for (final config in AiNewsSourcesConfig.sources)
      AiNewsSourceEntry(
        config: config,
        enabled: byId[config.id]?.enabled ?? true,
        isCustom: false,
        health: byId[config.id]?.health ?? const AiNewsSourceHealth(),
      ),
  ];
  final builtInIds = AiNewsSourcesConfig.sources.map((source) => source.id).toSet();
  result.addAll(stored.where((entry) => entry.isCustom && !builtInIds.contains(entry.config.id)));
  return result;
}

List<AiNewsSourceEntry>? _decodeStored(String? raw, {required bool strict}) {
  if (raw == null || raw.trim().isEmpty) {
    return strict ? null : const [];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Source document must be a list');
    }
    final result = <AiNewsSourceEntry>[];
    final ids = <String>{};
    final urls = <String>{};
    for (final item in decoded) {
      if (item is! Map) {
        throw const FormatException('Source entry must be an object');
      }
      final json = item.cast<String, Object?>();
      final id = _requiredString(json, 'id');
      final name = _requiredString(json, 'name');
      final feedUrl = _normalizeUrl(_requiredString(json, 'feedUrl'));
      final category = _requiredString(json, 'categoryCode');
      if (!AiNewsSourcesConfig.supportedCategoryCodes.contains(category) || !ids.add(id) || !urls.add(feedUrl.toLowerCase())) {
        throw const FormatException('Duplicate or unsupported source entry');
      }
      result.add(
        AiNewsSourceEntry(
          config: AiNewsSourceConfig(id: id, name: name, feedUrl: feedUrl, categoryCode: category),
          enabled: json['enabled'] is bool ? json['enabled']! as bool : true,
          isCustom: json['isCustom'] is bool ? json['isCustom']! as bool : false,
          health: AiNewsSourceHealth(
            consecutiveFailures: _nonNegativeInt(json['consecutiveFailures']),
            lastSuccessAt: _date(json['lastSuccessAt']),
            lastFailureAt: _date(json['lastFailureAt']),
            lastError: json['lastError'] is String ? json['lastError']! as String : null,
          ),
        ),
      );
    }
    return result;
  } catch (_) {
    if (strict) {
      rethrow;
    }
    return null;
  }
}

String _normalizeUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority || (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw const FormatException('Source URL must be an absolute HTTP(S) URL');
  }
  final serialized = uri.toString();
  return uri.hasFragment ? serialized.substring(0, serialized.lastIndexOf('#')) : serialized;
}

String _customId(String url) {
  var hash = 0;
  for (final unit in url.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return 'custom_$hash';
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing source field: $key');
  }
  return value.trim();
}

int _nonNegativeInt(Object? raw) => raw is num ? raw.toInt().clamp(0, 999999) : 0;

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
