import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';

/*
 *`combineFreshness` 是多来源聚合的唯一合并口径。
 *
 *合并必须保守:任何一个来源不完整,整体就不能宣称更完整的新鲜度。
 *这里逐条锁住规则,防止将来新增 `DataFreshness` 成员时又被静默降级。
 */
void main() {
  group('combineFreshness', () {
    test('an empty source list has no freshness to claim', () {
      expect(combineFreshness(const []), DataFreshness.seed);
    });

    test('a single source keeps its own freshness', () {
      for (final freshness in DataFreshness.values) {
        expect(combineFreshness([freshness]), freshness, reason: '$freshness 应原样保留');
      }
    });

    test('all-seed sources stay on seed', () {
      expect(combineFreshness([DataFreshness.seed, DataFreshness.seed]), DataFreshness.seed);
    });

    test('a live source wins over a cached source', () {
      expect(combineFreshness([DataFreshness.live, DataFreshness.freshCache]), DataFreshness.live);
    });

    test('cached sources without a live source stay cached', () {
      expect(combineFreshness([DataFreshness.freshCache, DataFreshness.freshCache]), DataFreshness.freshCache);
    });

    test('a partial source downgrades a live source to partial', () {
      expect(combineFreshness([DataFreshness.live, DataFreshness.partial]), DataFreshness.partial);
    });

    test('a partial source is never reported as seed', () {
      expect(combineFreshness([DataFreshness.partial]), DataFreshness.partial);
      expect(combineFreshness([DataFreshness.partial, DataFreshness.freshCache]), DataFreshness.partial);
    });

    test('a stale source downgrades a partial source to stale', () {
      expect(combineFreshness([DataFreshness.partial, DataFreshness.staleCache]), DataFreshness.staleCache);
    });

    test('a seed source mixed with real data downgrades to stale', () {
      expect(combineFreshness([DataFreshness.live, DataFreshness.seed]), DataFreshness.staleCache);
    });

    test('combining never yields a fresher claim than the weakest source', () {
      const claims = DataFreshness.values;
      for (final a in claims) {
        for (final b in claims) {
          final combined = combineFreshness([a, b]);
          expect(claims, contains(combined), reason: '$a + $b 产生了未知档位 $combined');
          // seed 是最弱的档位,任何组合都不得比它更新鲜。
          if (a == DataFreshness.seed || b == DataFreshness.seed) {
            expect(combined, anyOf(DataFreshness.seed, DataFreshness.staleCache), reason: '$a + $b 不应宣称实时');
          }
        }
      }
    });
  });

  group('FreshnessRole', () {
    test('every freshness maps to a role', () {
      for (final freshness in DataFreshness.values) {
        expect(freshness.role, isNotNull, reason: '$freshness 缺少角色');
      }
    });

    test('live and cached roles never veto, partial and stale roles always do', () {
      expect(FreshnessRole.live.vetoes, isFalse);
      expect(FreshnessRole.cached.vetoes, isFalse);
      expect(FreshnessRole.partial.vetoes, isTrue);
      expect(FreshnessRole.stale.vetoes, isTrue);
      expect(FreshnessRole.seed.vetoes, isTrue);
    });

    test('stale is a stronger veto than partial', () {
      expect(FreshnessRole.stale.vetoSeverity, greaterThan(FreshnessRole.partial.vetoSeverity));
    });
  });
}
