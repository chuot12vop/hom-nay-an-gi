import 'package:flutter_test/flutter_test.dart';

import 'package:hom_nay_an_gi/controllers/base_home_controller.dart';
import 'package:hom_nay_an_gi/models/food.dart';
import 'package:hom_nay_an_gi/models/ingredient.dart';
import 'package:hom_nay_an_gi/models/meal.dart';
import 'package:hom_nay_an_gi/models/sheet_data.dart';
import 'package:hom_nay_an_gi/services/spin_history_service.dart';

Food _food(String id) => Food(
      id: id,
      name: 'n',
      categoryId: 'c',
      mealId: 'm',
      priceVnd: 1,
      ingredientIds: const <String>[],
    );

void main() {
  group('BaseHomeController.foodsFromIds', () {
    test('preserves order and skips unknown ids', () {
      final List<Food> all = <Food>[_food('1'), _food('2')];
      final List<Food> out = BaseHomeController.foodsFromIds(
        <String>['2', 'x', '1'],
        all,
      );
      expect(out.map((Food e) => e.id).toList(), <String>['2', '1']);
    });
  });

  group('BaseHomeController.onNavItemTapped', () {
    test('leaving wheel tab clears filters and bumps wheel session', () {
      final BaseHomeController c = BaseHomeController(
        fetchSheetData: () async => SheetData(
          foods: <Food>[],
          ingredients: <Ingredient>[],
          meals: <Meal>[],
        ),
        spinHistoryService: _FakeSpinHistory(),
      );
      c.selectedIndex = 2;
      c.filteredFoods = <Food>[_food('a')];
      c.wheelSession = 3;
      c.onNavItemTapped(0);
      expect(c.selectedIndex, 0);
      expect(c.filteredFoods, isEmpty);
      expect(c.wheelSession, 4);
    });
  });

  group('BaseHomeController.loadDefaultWheelFoods', () {
    test('maps sheet foods by history ids', () async {
      final Food a = _food('a');
      final Food b = _food('b');
      final BaseHomeController c = BaseHomeController(
        fetchSheetData: () async => SheetData(
          foods: <Food>[a, b],
          ingredients: <Ingredient>[],
          meals: <Meal>[],
        ),
        spinHistoryService: _FakeSpinHistory(ids: <String>['b', 'a']),
      );
      await c.loadDefaultWheelFoods();
      expect(c.defaultWheelLoading, false);
      expect(c.defaultWheelFoods.map((Food e) => e.id).toList(), <String>['b', 'a']);
    });
  });
}

class _FakeSpinHistory extends SpinHistoryService {
  _FakeSpinHistory({this.ids = const <String>[]});

  final List<String> ids;

  @override
  Future<List<String>> recentUniqueFoodIds(int limit) async {
    if (ids.length <= limit) {
      return List<String>.from(ids);
    }
    return ids.take(limit).toList();
  }

  @override
  Future<void> appendSpin(Food food) async {}
}
