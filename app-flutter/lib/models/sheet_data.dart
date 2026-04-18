import 'food.dart';
import 'ingredient.dart';
import 'meal.dart';

class SheetData {
  const SheetData({
    required this.foods,
    required this.ingredients,
    required this.meals,
  });

  final List<Food> foods;
  final List<Ingredient> ingredients;
  final List<Meal> meals;
}
