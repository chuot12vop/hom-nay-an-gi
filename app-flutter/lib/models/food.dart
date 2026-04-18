class Food {
  const Food({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.mealId,
    required this.priceVnd,
    required this.ingredientIds,
  });

  final int id;
  final String name;
  final int categoryId;
  final int mealId;
  final int priceVnd;
  final List<int> ingredientIds;
}
