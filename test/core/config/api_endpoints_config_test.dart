import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';

void main() {
  test('githubSearchUsersPath 为 /search/users', () {
    expect(ApiEndpointsConfig.githubSearchUsersPath, '/search/users');
  });

  test('githubSearchUsersUrl 默认参数拼装', () {
    final url = ApiEndpointsConfig.githubSearchUsersUrl(q: 'type:org followers:>5000');
    // Uri.encodeQueryComponent 按 application/x-www-form-urlencoded 编码,
    // 空格 -> '+'(与现有 githubSearchRepositoriesUrl 一致)。
    expect(url, contains('q=type%3Aorg+followers%3A%3E5000'));
    expect(url, contains('per_page=20'));
    expect(url, contains('page=1'));
  });

  test('githubSearchUsersUrl 自定义分页', () {
    final url = ApiEndpointsConfig.githubSearchUsersUrl(q: 'ai', perPage: 50, page: 3);
    expect(url, contains('per_page=50'));
    expect(url, contains('page=3'));
  });
}
