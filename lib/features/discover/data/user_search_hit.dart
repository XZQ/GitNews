/*
 *`/search/users` 单条结果的轻量值对象。
 *
 *仅包含搜索接口返回的字段;bio / followers / public_repos 等
 *需通过 `/users/{login}` 渐进补全。
 */
class UserSearchHit {
  const UserSearchHit({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.type,
  });

  final String login;
  final String avatarUrl;
  final String htmlUrl;

  // GitHub 返回的 'User' 或 'Organization'。
  final String type;
}
