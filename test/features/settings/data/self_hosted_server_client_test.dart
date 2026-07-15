import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/preferences/server_connection_controller.dart';
import 'package:github_news/features/settings/data/self_hosted_server_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late SelfHostedServerClient client;
  const connection = ServerConnectionState(
    baseUrl: 'https://sync.example.com',
    workspaceId: 'team-a',
    memberId: 'desktop-a',
    apiKey: 'secret',
  );

  setUp(() {
    dio = _MockDio();
    client = SelfHostedServerClient(dio);
  });

  test('health check accepts the server contract', () async {
    when(() => dio.get<Map<String, Object?>>(any())).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/health'),
        data: {'status': 'ok'},
      ),
    );

    await client.checkHealth(connection);

    verify(() => dio.get<Map<String, Object?>>('https://sync.example.com/health')).called(1);
  });

  test('push config reports a remote version conflict', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/v1/sync/push'),
        data: {
          'accepted': 0,
          'conflicts': [
            {'version': 99},
          ],
        },
      ),
    );

    expect(
      () => client.pushConfig(connection, const {}, version: 1),
      throwsA(isA<StateError>()),
    );
  });

  test('pull config selects the shared app config record', () async {
    when(
      () => dio.get<List<Object?>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/v1/sync/pull'),
        data: [
          {
            'workspace_id': 'team-a',
            'namespace': 'app_config',
            'record_id': 'shared',
            'payload': {
              'app': 'github_news',
              'version': 1,
              'preferences': <String, Object?>{},
            },
            'version': 42,
          },
        ],
      ),
    );

    final record = await client.pullConfig(connection);

    expect(record?.version, 42);
    expect(record?.payload['app'], 'github_news');
  });
}
