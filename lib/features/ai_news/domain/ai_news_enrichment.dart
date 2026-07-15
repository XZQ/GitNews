class AiNewsEntities {
  const AiNewsEntities({
    this.models = const [],
    this.companies = const [],
    this.repositories = const [],
  });

  final List<String> models;
  final List<String> companies;
  final List<String> repositories;

  List<String> get all => {...models, ...companies, ...repositories}.toList();
}

/* LLM 对单条资讯生成的结构化增强，不覆盖原始内容。 */
class AiNewsEnrichment {
  const AiNewsEnrichment({
    required this.itemId,
    required this.generatedSummary,
    required this.translatedTitle,
    required this.translatedSummary,
    required this.importanceScore,
    required this.entities,
    required this.model,
    required this.updatedAt,
  });

  final String itemId;
  final String generatedSummary;
  final String translatedTitle;
  final String translatedSummary;
  final double importanceScore;
  final AiNewsEntities entities;
  final String model;
  final DateTime updatedAt;
}
