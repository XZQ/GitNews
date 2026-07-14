/*
*单条 AI 资讯的本机用户状态(已读 / 稍后读)。
*与条目内容分离存储:内容是可清理的缓存,状态是用户数据。
*/
class AiNewsItemState {
  const AiNewsItemState({this.readAt, this.readLaterAt});

  static const AiNewsItemState none = AiNewsItemState();

  final DateTime? readAt;
  final DateTime? readLaterAt;

  bool get isRead => readAt != null;
  bool get isReadLater => readLaterAt != null;
}
