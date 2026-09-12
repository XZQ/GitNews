import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/features/ai_news/data/ai_digest_llm_client.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  final item = AiNewsItem(
    id: 'article',
    category: AiNewsCategory.industry,
    title: 'Title',
    titleEn: '',
    summary: 'Summary',
    source: 'Source',
    url: 'https://news.example/article',
    permalink: '',
    publishedAt: DateTime.utc(2026),
    score: 1,
    selected: true,
  );
  late _MockDio dio;
  setUpAll(() => registerFallbackValue(Options()));
  setUp(() {
    dio = _MockDio();
  });

  test('sends only article fields to the proxy with a user session and no redirects', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/v1/ai/enrichment'),
        data: {
          'model': 'agnes-2.0-flash',
          'enrichment': {'generated_summary': '摘要'},
        },
      ),
    );
    final client = AiDigestLlmClient(dio, serviceUrl: 'https://proxy.example');
    final raw = await client.enrich(accessToken: 'user-session-fixture', item: item);
    final captured = verify(
      () => dio.post<Map<String, Object?>>(
        'https://proxy.example/v1/ai/enrichment',
        data: captureAny(named: 'data'),
        options: captureAny(named: 'options'),
      ),
    ).captured;
    expect((captured[0] as Map).keys.toSet(), {'title', 'title_en', 'summary', 'source', 'url'});
    final options = captured[1] as Options;
    expect(options.headers?['Authorization'], 'Bearer user-session-fixture');
    expect(options.followRedirects, isFalse);
    expect(options.maxRedirects, 0);
    expect((jsonDecode(raw) as Map<String, Object?>)['generated_summary'], '摘要');
  });

  for (final address in ['http://remote.example', 'https://user:password@proxy.example', 'https://proxy.example?token=fixture', 'https://proxy.example/path']) {
    test('rejects unsafe proxy origin $address before sending a user session', () async {
      final client = AiDigestLlmClient(dio, serviceUrl: address);
      await expectLater(client.enrich(accessToken: 'user-session-fixture', item: item), throwsA(isA<AppException>()));
      verifyNever(
        () => dio.post<Map<String, Object?>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });
  }

  test('transport failure does not retain request headers in the surfaced exception', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/v1/ai/enrichment', headers: {'Authorization': 'user-session-fixture'}),
      ),
    );
    final client = AiDigestLlmClient(dio, serviceUrl: 'https://proxy.example');
    await expectLater(client.enrich(accessToken: 'user-session-fixture', item: item), throwsA(isA<AppException>().having((error) => error.cause, 'cause', isNull)));
  });
}
