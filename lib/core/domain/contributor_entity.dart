/* 
*仓库贡献者实体。
*/
class ContributorEntity {
  const ContributorEntity({required this.login, required this.contributions, required this.avatarAccentArgb});

  final String login;
  final int contributions;

  // 头像底色 32-bit ARGB。
  final int avatarAccentArgb;
}
