import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/data/dto/ai_news_item_dto.dart';

void main() {
  group('AiNewsListResponseDto 坏条目隔离', () {
    test('缺失或非字符串 id 的条目被跳过,不毁掉整页主源', () {
      final dto = AiNewsListResponseDto.fromJson({
        'count': 4,
        'hasNext': false,
        'items': [
          {'id': 'good-1', 'title': '正常条目'},
          {'title': '缺 id'},
          {'id': null, 'title': 'id 为 null'},
          {'id': 42, 'title': 'id 非字符串'},
          {'id': '', 'title': '空 id'},
          {'id': 'good-2', 'title': '另一条正常'},
          'not-a-map',
        ],
      });

      expect(dto.items.map((item) => item.id), ['good-1', 'good-2']);
    });

    test('items 缺失或非列表时返回空列表', () {
      expect(AiNewsListResponseDto.fromJson({'count': 0}).items, isEmpty);
      expect(AiNewsListResponseDto.fromJson({'items': 'broken'}).items, isEmpty);
    });
  });
}
