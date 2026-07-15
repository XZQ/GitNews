import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/preferences/server_connection_controller.dart';

class RemoteConfigRecord {
  const RemoteConfigRecord({required this.payload, required this.version});

  final Map<String, Object?> payload;
  final int version;
}

class SelfHostedServerClient {
  const SelfHostedServerClient(this._dio);

  final Dio _dio;

  Future<void> checkHealth(ServerConnectionState connection) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '${connection.baseUrl}/health',
      );
      if (response.data?['status'] != 'ok') {
        // 统一异常边界:presentation 只应见到 AppException。
        throw const AppException(
          kind: AppExceptionKind.parse,
          meta: {'reason': 'unexpected health payload'},
        );
      }
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  Future<void> registerMember(ServerConnectionState connection) async {
    try {
      await _dio.put<Map<String, Object?>>(
        '${connection.baseUrl}/v1/collaboration/members/${Uri.encodeComponent(connection.memberId)}',
        data: {
          'member_id': connection.memberId,
          'display_name': connection.memberId,
          'role': 'owner',
        },
        options: _options(connection),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  Future<void> pushConfig(
    ServerConnectionState connection,
    Map<String, Object?> payload, {
    required int version,
  }) async {
    try {
      final response = await _dio.post<Map<String, Object?>>(
        '${connection.baseUrl}/v1/sync/push',
        data: {
          'records': [
            {
              'namespace': 'app_config',
              'record_id': 'shared',
              'payload': payload,
              'version': version,
              'updated_at': version,
            },
          ],
        },
        options: _options(connection),
      );
      final conflicts = response.data?['conflicts'];
      if (conflicts is List && conflicts.isNotEmpty) {
        // 冲突是唯一需要用户采取不同动作(先拉取)的失败,单独标记
        // 让上层给出针对性提示,而不是笼统的「操作失败」。
        throw const AppException(
          kind: AppExceptionKind.unknown,
          meta: {'reason': 'conflict'},
        );
      }
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  Future<RemoteConfigRecord?> pullConfig(
    ServerConnectionState connection,
  ) async {
    try {
      final response = await _dio.get<List<Object?>>(
        '${connection.baseUrl}/v1/sync/pull',
        queryParameters: {'since': 0, 'limit': 1000},
        options: _options(connection),
      );
      final rows = response.data ?? const [];
      for (final raw in rows.reversed) {
        if (raw is! Map) {
          continue;
        }
        final row = raw.cast<String, Object?>();
        if (row['namespace'] != 'app_config' || row['record_id'] != 'shared' || row['payload'] is! Map) {
          continue;
        }
        return RemoteConfigRecord(
          payload: (row['payload'] as Map).cast<String, Object?>(),
          version: row['version'] as int,
        );
      }
      return null;
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  Options _options(ServerConnectionState connection) {
    return Options(
      headers: {
        'Authorization': 'Bearer ${connection.apiKey}',
        'X-Workspace-ID': connection.workspaceId,
        'Content-Type': 'application/json',
      },
    );
  }
}
