/// Một dòng trong tab Sheet "videos" (short / clip gợi ý).
class SheetShortVideo {
  const SheetShortVideo({
    required this.id,
    this.url,
    this.thumbnailUrl,
    this.category,
    this.foodId,
    this.mealId,
  });

  final String id;
  final String? url;
  final String? thumbnailUrl;
  final String? category;
  final String? foodId;
  final String? mealId;
}
