import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/discover/data/discover_users_search_client.dart';

void main() {
  test('searchUsers 透传 query/page/perPage 并解析 login 列表', () async {
    final dio = Dio();
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;

    final client = DiscoverUsersSearchClient(dio, 'fake-token');
    final hits = await client.searchUsers(
      query: 'type:org followers:>5000',
      page: 2,
      perPage: 30,
    );

    // 客户端通过 `ApiEndpointsConfig.githubSearchUsersUrl` 预拼 query string,
    // Dio 把整串塞进 path,queryParameters 为空。这里用 Uri 解出 path/query。
    final uri = Uri.parse(adapter.lastPath!);
    expect(uri.path, '/search/users');
    expect(uri.queryParameters['q'], 'type:org followers:>5000');
    expect(uri.queryParameters['page'], '2');
    expect(uri.queryParameters['per_page'], '30');
    expect(adapter.lastHeaders!['Authorization'], 'Bearer fake-token');
    expect(hits.length, 2);
    expect(hits[0].login, 'openai');
    expect(hits[0].type, 'Organization');
    expect(hits[1].login, 'karpathy');
    expect(hits[1].type, 'User');
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? lastPath;
  Map<String, dynamic>? lastHeaders;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    // Dio 把 githubSearchUsersUrl 预拼的整串放进 path,queryParameters 为空,
    // 故查询参数从 lastPath 用 Uri.parse 解出。
    lastHeaders = options.headers;
    final payload = jsonEncode({
      'items': [
        {
          'login': 'openai',
          'avatar_url': 'https://github.com/openai.png',
          'html_url': 'https://github.com/openai',
          'type': 'Organization',
        },
        {
          'login': 'karpathy',
          'avatar_url': 'https://github.com/karpathy.png',
          'html_url': 'https://github.com/karpathy',
          'type': 'User',
        },
      ],
    });
    return ResponseBody.fromString(
      payload,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
