import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/features/profile/data/github_rate_limit_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late GitHubRateLimitClient client;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    client = GitHubRateLimitClient(dio);
  });

  group('GitHubRateLimitClient.fetch', () {
    test('should parse core and search rate limit buckets', () async {
      when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => _okResponse(_body()));

      final snapshot = await client.fetch();

      expect(snapshot.core.limit, 60);
      expect(snapshot.core.remaining, 58);
      expect(snapshot.search.limit, 10);
      expect(snapshot.search.remaining, 9);
    });

    test('should send bearer token when token is configured', () async {
      Options? capturedOptions;
      when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((invocation) async {
        capturedOptions = invocation.namedArguments[#options] as Options;
        return _okResponse(_body());
      });

      await client.fetch(token: 'github_pat_test');

      expect(capturedOptions?.headers?['Authorization'], 'Bearer github_pat_test');
    });

    test('should throw parse AppException when response is malformed', () async {
      when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options'))).thenAnswer((_) async => _okResponse(<String, Object?>{}));

      await expectLater(client.fetch(), throwsA(predicate<AppException>((e) => e.kind == AppExceptionKind.parse)));
    });

    test('should map DioException to AppException', () async {
      when(() => dio.get<Map<String, Object?>>(any(), options: any(named: 'options')))
          .thenThrow(DioException(type: DioExceptionType.connectionError, requestOptions: RequestOptions(path: ApiEndpointsConfig.githubRateLimitPath)));

      await expectLater(client.fetch(), throwsA(predicate<AppException>((e) => e.kind == AppExceptionKind.network)));
    });
  });
}

Response<Map<String, Object?>> _okResponse(Map<String, Object?> body) {
  return Response<Map<String, Object?>>(requestOptions: RequestOptions(path: ApiEndpointsConfig.githubRateLimitPath), statusCode: 200, data: body);
}

Map<String, Object?> _body() {
  return <String, Object?>{
    'resources': <String, Object?>{
      'core': <String, Object?>{'limit': 60, 'remaining': 58, 'reset': 1783168200},
      'search': <String, Object?>{'limit': 10, 'remaining': 9, 'reset': 1783168200}
    }
  };
}
