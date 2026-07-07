/* 
*数值短格式化:`1234 → 1.2k`、`1_500_000 → 1.5M`。
*/
String shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}
