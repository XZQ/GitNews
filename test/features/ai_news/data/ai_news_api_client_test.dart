import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/features/ai_news/data/ai_news_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, Object?>> _okResponse(Map<String, Object?> body) {
  return Response<Map<String, Object?>>(
    requestOptions: RequestOptions(path: ApiEndpointsConfig.aiNewsItemsPath),
    statusCode: 200,
    data: body,
  );
}

void main() {
  late _MockDio dio;
  late AiNewsApiClient client;

  setUp(() {
    dio = _MockDio();
    client = AiNewsApiClient.create(dio);
    registerFallbackValue(RequestOptions(path: '/'));
  });

  group('AiNewsApiClient.fetchItems 异常边界', () {
    test('should throw network AppException on connectionError', () async {
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/x'),
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>((e) => e.kind == AppExceptionKind.network),
        ),
      );
    });

    test('should throw network AppException on transformTimeout', () async {
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/x'),
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>((e) => e.kind == AppExceptionKind.network),
        ),
      );
    });

    test('should throw rateLimit AppException on 429 with Retry-After',
        () async {
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/x'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
          ),
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>(
            (e) =>
                e.kind == AppExceptionKind.rateLimit &&
                e.retryAfterSeconds == 30,
          ),
        ),
      );
    });

    test('should throw server AppException on 5xx', () async {
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/x'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 503,
          ),
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>((e) => e.kind == AppExceptionKind.server),
        ),
      );
    });

    test('should throw parse AppException when data is null', () async {
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, Object?>>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
          data: null,
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>((e) => e.kind == AppExceptionKind.parse),
        ),
      );
    });

    test('should throw parse AppException on type-mismatched field', () async {
      // count 字段是 String 而非 num,`(json['count'] as num?)` 抛 TypeError,
      // 经 Repository 边界转换为 AppException(parse),禁止透传 UI。
      when(
        () => dio.get<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _okResponse(
          <String, Object?>{
            'count': 'not-a-number',
            'items': <Object>[],
          },
        ),
      );
      await expectLater(
        client.fetchItems(),
        throwsA(
          predicate<AppException>((e) => e.kind == AppExceptionKind.parse),
        ),
      );
    });
  });
}
