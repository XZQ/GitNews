import 'dart:convert';

import '../domain/contributor_entity.dart';
import '../domain/repo_entity.dart';

const int _fallbackAccentArgb = 0xFF64748B;

class SavedRepoSnapshot {
  const SavedRepoSnapshot(
      {required this.fullName, required this.description, required this.language, required this.starCount, required this.forkCount, required this.accentArgb, required this.updatedAt});

  factory SavedRepoSnapshot.fromEntity(RepoEntity repo, DateTime now) {
    return SavedRepoSnapshot(
      fullName: repo.fullName,
      description: repo.description,
      language: repo.language,
      starCount: repo.starCount,
      forkCount: repo.forkCount,
      accentArgb: repo.accentArgb,
      updatedAt: now.toUtc(),
    );
  }

  factory SavedRepoSnapshot.minimal(String fullName, DateTime now) {
    return SavedRepoSnapshot(
      fullName: fullName,
      description: '',
      language: 'Unknown',
      starCount: 0,
      forkCount: 0,
      accentArgb: _fallbackAccentArgb,
      updatedAt: now.toUtc(),
    );
  }

  factory SavedRepoSnapshot.fromJson(Map<String, Object?> json) {
    return SavedRepoSnapshot(
      fullName: _string(json, 'fullName'),
      description: _string(json, 'description'),
      language: _string(json, 'language'),
      starCount: _integer(json, 'starCount'),
      forkCount: _integer(json, 'forkCount'),
      accentArgb: _integer(json, 'accentArgb'),
      updatedAt: DateTime.parse(_string(json, 'updatedAt')).toUtc(),
    );
  }

  final String fullName;
  final String description;
  final String language;
  final int starCount;
  final int forkCount;
  final int accentArgb;
  final DateTime updatedAt;

  RepoEntity toEntity() {
    return RepoEntity(
      fullName: fullName,
      description: description,
      language: language,
      starCount: starCount,
      starDelta: 0,
      forkCount: forkCount,
      accentArgb: accentArgb,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'fullName': fullName,
      'description': description,
      'language': language,
      'starCount': starCount,
      'forkCount': forkCount,
      'accentArgb': accentArgb,
      'updatedAt': updatedAt.toUtc().toIso8601String()
    };
  }
}

class SavedDeveloperSnapshot {
  const SavedDeveloperSnapshot({
    required this.login,
    required this.contributions,
    required this.avatarAccentArgb,
    required this.updatedAt,
  });

  factory SavedDeveloperSnapshot.fromEntity(ContributorEntity developer, DateTime now) {
    return SavedDeveloperSnapshot(
      login: developer.login,
      contributions: developer.contributions,
      avatarAccentArgb: developer.avatarAccentArgb,
      updatedAt: now.toUtc(),
    );
  }

  factory SavedDeveloperSnapshot.minimal(String login, DateTime now) {
    return SavedDeveloperSnapshot(
      login: login,
      contributions: 0,
      avatarAccentArgb: _fallbackAccentArgb,
      updatedAt: now.toUtc(),
    );
  }

  factory SavedDeveloperSnapshot.fromJson(Map<String, Object?> json) {
    return SavedDeveloperSnapshot(
      login: _string(json, 'login'),
      contributions: _integer(json, 'contributions'),
      avatarAccentArgb: _integer(json, 'avatarAccentArgb'),
      updatedAt: DateTime.parse(_string(json, 'updatedAt')).toUtc(),
    );
  }

  final String login;
  final int contributions;
  final int avatarAccentArgb;
  final DateTime updatedAt;

  ContributorEntity toEntity() {
    return ContributorEntity(login: login, contributions: contributions, avatarAccentArgb: avatarAccentArgb);
  }

  Map<String, Object?> toJson() {
    return {'login': login, 'contributions': contributions, 'avatarAccentArgb': avatarAccentArgb, 'updatedAt': updatedAt.toUtc().toIso8601String()};
  }
}

Map<String, SavedRepoSnapshot> decodeRepoSnapshots(String? raw) {
  return _decodeSnapshots(raw, SavedRepoSnapshot.fromJson, (item) => item.fullName);
}

Map<String, SavedDeveloperSnapshot> decodeDeveloperSnapshots(String? raw) {
  return _decodeSnapshots(raw, SavedDeveloperSnapshot.fromJson, (item) => item.login);
}

String encodeRepoSnapshots(Map<String, SavedRepoSnapshot> snapshots) {
  return _encodeSnapshots(snapshots, (item) => item.toJson());
}

String encodeDeveloperSnapshots(Map<String, SavedDeveloperSnapshot> snapshots) {
  return _encodeSnapshots(snapshots, (item) => item.toJson());
}

Map<String, T> _decodeSnapshots<T>(String? raw, T Function(Map<String, Object?>) decode, String Function(T) idOf) {
  if (raw == null || raw.trim().isEmpty) {
    return <String, T>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <String, T>{};
    }
    final result = <String, T>{};
    for (final value in decoded) {
      if (value is! Map) {
        continue;
      }
      try {
        final item = decode(value.cast<String, Object?>());
        final id = idOf(item).trim();
        if (id.isNotEmpty) {
          result[id] = item;
        }
      } catch (_) {
        continue;
      }
    }
    return result;
  } catch (_) {
    return <String, T>{};
  }
}

String _encodeSnapshots<T>(Map<String, T> snapshots, Map<String, Object?> Function(T) encode) {
  final keys = snapshots.keys.toList()..sort();
  return jsonEncode([for (final key in keys) encode(snapshots[key] as T)]);
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected string for $key');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Expected number for $key');
  }
  return value.toInt();
}
