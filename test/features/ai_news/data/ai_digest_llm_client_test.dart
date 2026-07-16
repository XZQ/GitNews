import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/data/ai_digest_llm_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late AiDigestLlmClient client;

  setUp(() {
    dio = _MockDio();
    client = AiDigestLlmClient(dio);
  });

  test('请求不固定 temperature 并兼容文本分段响应', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, Object?>>(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: 200,
        data: {
          'choices': [
            {
              'message': {
                'content': [
                  {'type': 'text', 'text': '第一段'},
                  {'type': 'text', 'text': '第二段'},
                ],
              },
            },
          ],
        },
      ),
    );

    final result = await client.complete(
      baseUrl: 'https://example.com/v1',
      apiKey: 'secret',
      model: 'model-id',
      systemPrompt: 'system',
      userPrompt: 'user',
    );
    final captured = verify(
      () => dio.post<Map<String, Object?>>(
        any(),
        data: captureAny(named: 'data'),
        options: any(named: 'options'),
      ),
    ).captured.single as Map<String, Object?>;

    expect(result, '第一段第二段');
    expect(captured.containsKey('temperature'), isFalse);
    expect(captured['model'], 'model-id');
  });
}
