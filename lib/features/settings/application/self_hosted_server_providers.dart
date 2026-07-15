import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/preferences/config_service.dart';
import '../../../core/preferences/server_connection_controller.dart';
import '../data/self_hosted_server_client.dart';

enum ServerOperation { idle, testing, pushing, pulling }

class SelfHostedServerStatus {
  const SelfHostedServerStatus({
    this.operation = ServerOperation.idle,
    this.messageKey,
    this.error = false,
    this.lastSuccessAt,
  });

  final ServerOperation operation;
  final String? messageKey;
  final bool error;
  final DateTime? lastSuccessAt;

  bool get busy => operation != ServerOperation.idle;
}

final selfHostedServerDioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  ),
);

final selfHostedServerClientProvider = Provider<SelfHostedServerClient>(
  (ref) => SelfHostedServerClient(ref.watch(selfHostedServerDioProvider)),
);

final selfHostedServerControllerProvider = NotifierProvider<SelfHostedServerController, SelfHostedServerStatus>(
  SelfHostedServerController.new,
);

class SelfHostedServerController extends Notifier<SelfHostedServerStatus> {
  @override
  SelfHostedServerStatus build() => const SelfHostedServerStatus();

  Future<void> testConnection() async {
    await _run(ServerOperation.testing, () async {
      final connection = _connection();
      await ref.read(selfHostedServerClientProvider).checkHealth(connection);
      await ref.read(selfHostedServerClientProvider).registerMember(connection);
    }, 'settings.server.connected');
  }

  Future<void> pushConfig() async {
    await _run(ServerOperation.pushing, () async {
      final text = await ref.read(configServiceProvider).exportText();
      final payload = (jsonDecode(text) as Map).cast<String, Object?>();
      final version = DateTime.now().toUtc().millisecondsSinceEpoch;
      await ref.read(selfHostedServerClientProvider).pushConfig(_connection(), payload, version: version);
    }, 'settings.server.pushed');
  }

  Future<void> pullConfig() async {
    await _run(ServerOperation.pulling, () async {
      final record = await ref.read(selfHostedServerClientProvider).pullConfig(_connection());
      if (record == null) {
        throw StateError('Remote config not found');
      }
      await ref.read(configServiceProvider).importText(jsonEncode(record.payload));
    }, 'settings.server.pulled');
  }

  Future<void> _run(
    ServerOperation operation,
    Future<void> Function() action,
    String successKey,
  ) async {
    if (state.busy) {
      return;
    }
    state = SelfHostedServerStatus(operation: operation);
    try {
      await action();
      state = SelfHostedServerStatus(
        messageKey: successKey,
        lastSuccessAt: DateTime.now().toUtc(),
      );
    } on AppException catch (e) {
      // 推送冲突需要用户先拉取,给针对性提示而非笼统失败。
      final conflict = e.meta['reason'] == 'conflict';
      state = SelfHostedServerStatus(
        messageKey: conflict ? 'settings.server.conflict' : 'settings.server.failed',
        error: true,
      );
    } catch (_) {
      state = const SelfHostedServerStatus(
        messageKey: 'settings.server.failed',
        error: true,
      );
    }
  }

  ServerConnectionState _connection() {
    final connection = ref.read(serverConnectionControllerProvider);
    if (!connection.configured) {
      throw StateError('Server connection is not configured');
    }
    return connection;
  }
}
