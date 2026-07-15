import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/network/dio_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late _MockHttpClientAdapter adapter;
  late Dio dio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    adapter = _MockHttpClientAdapter();
    dio = DioClient.create(baseUrl: 'https://api.test.com');
    dio.httpClientAdapter = adapter;
  });

  group('DioClient retry interceptor', () {
    test('200 success → no retry', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
        return ResponseBody.fromString('{"ok":true}', 200, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
      });

      final response = await dio.get<dynamic>('/test');

      expect(response.statusCode, 200);
      verify(() => adapter.fetch(any(), any(), any())).called(1);
    });

    test('500 error → retries 2 times then fails', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
        return ResponseBody.fromString('{"error":"internal"}', 500, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
      });

      await expectLater(dio.get<dynamic>('/test'), throwsA(isA<DioException>()));

      // 1 initial attempt + 2 retries = 3 adapter calls
      verify(() => adapter.fetch(any(), any(), any())).called(3);
    });

    test('429 error → no retry, immediate failure', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
        return ResponseBody.fromString('{"error":"rate limit"}', 429, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
      });

      await expectLater(dio.get<dynamic>('/test'), throwsA(predicate<DioException>((e) => e.response?.statusCode == 429)));

      verify(() => adapter.fetch(any(), any(), any())).called(1);
    });

    test('404 error → no retry, immediate failure', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
        return ResponseBody.fromString('{"error":"not found"}', 404, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
      });

      await expectLater(dio.get<dynamic>('/test'), throwsA(predicate<DioException>((e) => e.response?.statusCode == 404)));

      verify(() => adapter.fetch(any(), any(), any())).called(1);
    });

    test('network error → retries 2 times then fails', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
        final requestOptions = invocation.positionalArguments[0] as RequestOptions;
        throw DioException(type: DioExceptionType.connectionError, requestOptions: requestOptions);
      });

      await expectLater(dio.get<dynamic>('/test'), throwsA(isA<DioException>()));

      // 1 initial attempt + 2 retries = 3 adapter calls
      verify(() => adapter.fetch(any(), any(), any())).called(3);
    });
  });
}
