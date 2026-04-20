import 'food.dart';
import 'ingredient.dart';
import 'meal.dart';
import 'sheet_short_video.dart';

class SheetData {
  const SheetData({
    required this.foods,
    required this.ingredients,
    required this.meals,
    this.shortVideos = const <SheetShortVideo>[],
  });

  final List<Food> foods;
  final List<Ingredient> ingredients;
  final List<Meal> meals;
  final List<SheetShortVideo> shortVideos;
}
