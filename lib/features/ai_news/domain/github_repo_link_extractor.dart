/*
*从资讯文本/链接中抽取 GitHub 仓库 `owner/repo`(纯函数)。
*资讯与 GitHub 两侧打通的入口:详情页据此展示「相关仓库」,
*点击复用现有仓库详情页(收藏/监控能力随之可用)。
*/

// github.com 下不是「owner」的保留一级路径。
const Set<String> _kReservedOwners = {
  'about',
  'apps',
  'blog',
  'collections',
  'contact',
  'customer-stories',
  'enterprise',
  'events',
  'explore',
  'features',
  'issues',
  'login',
  'marketplace',
  'new',
  'notifications',
  'orgs',
  'pricing',
  'pulls',
  'readme',
  'search',
  'security',
  'settings',
  'sponsors',
  'topics',
  'trending'
};

final RegExp _kRepoPattern = RegExp(r'github\.com/([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9._-]+)', caseSensitive: false);

/*
*抽取去重后的仓库全名列表(保持出现顺序,默认最多 [limit] 个)。
*[texts] 依次传入标题、摘要、原文链接等字段。
*/
List<String> extractGitHubRepoLinks(Iterable<String> texts, {int limit = 5}) {
  final seen = <String>{};
  final repos = <String>[];
  for (final text in texts) {
    if (repos.length >= limit) {
      break;
    }
    for (final match in _kRepoPattern.allMatches(text)) {
      final owner = match.group(1)!;
      var repo = match.group(2)!;
      // 去掉常见的尾缀噪声:`.git`、句读符。
      if (repo.toLowerCase().endsWith('.git')) {
        repo = repo.substring(0, repo.length - 4);
      }
      repo = repo.replaceAll(RegExp(r'[.,;:!?]+$'), '');
      if (repo.isEmpty || _kReservedOwners.contains(owner.toLowerCase())) {
        continue;
      }
      final fullName = '$owner/$repo';
      if (seen.add(fullName.toLowerCase())) {
        repos.add(fullName);
        if (repos.length >= limit) {
          break;
        }
      }
    }
  }
  return repos;
}
