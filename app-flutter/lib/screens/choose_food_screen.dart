import 'dart:math';

import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import '../models/food.dart';
import '../models/ingredient.dart';
import '../models/meal.dart';
import '../models/saved_filters.dart';
import '../models/sheet_data.dart';
import '../services/filter_storage_service.dart';
import '../services/google_sheet_service.dart';
import '../services/common_service.dart';
import '../widgets/gradient_widgets.dart';


class ChooseFoodScreen extends StatefulWidget {
  const ChooseFoodScreen({
    required this.onFoodsFiltered,
    required this.onOpenWheelRequested,
    super.key,
  });

  final ValueChanged<List<Food>> onFoodsFiltered;
  final VoidCallback onOpenWheelRequested;

  @override
  State<ChooseFoodScreen> createState() => _ChooseFoodScreenState();
}

class _ChooseFoodScreenState extends State<ChooseFoodScreen> {
  final GoogleSheetService _sheetService = GoogleSheetService();
  final FilterStorageService _storageService = FilterStorageService();

  SheetData? _sheetData;
  String? _selectedMealId;
  double _maxPrice = 70000;
  double _sliderMinPrice = 10000;
  double _sliderMaxPrice = 300000;
  final Set<String> _selectedAllergicIngredientIds = <String>{};

  bool _isLoading = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _applyPriceBoundsFromFoods(List<Food> foods) {
    if (foods.isEmpty) {
      _sliderMinPrice = 10000;
      _sliderMaxPrice = 300000;
      return;
    }
    final List<int> prices = foods.map((Food f) => f.priceVnd).toList();
    _sliderMinPrice = prices.reduce(min).toDouble();
    _sliderMaxPrice = prices.reduce(max).toDouble();
    if (_sliderMinPrice >= _sliderMaxPrice) {
      _sliderMaxPrice = _sliderMinPrice + 1000;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _feedback = null;
    });

    final SheetData data = await _sheetService.fetchAllTables();
    final SavedFilters? savedFilters = await _storageService.read();
    if (!mounted) {
      return;
    }

    _applyPriceBoundsFromFoods(data.foods);

    setState(() {
      _sheetData = data;
      _isLoading = false;

      if (savedFilters != null) {
        final bool hasMeal = data.meals.any((Meal meal) => meal.id == savedFilters.mealId);
        _selectedMealId = hasMeal ? savedFilters.mealId : null;
        _maxPrice = savedFilters.maxPriceVnd.toDouble().clamp(_sliderMinPrice, _sliderMaxPrice);

        final Set<String> validIngredientIds =
            data.ingredients.map((Ingredient i) => i.id).toSet();
        _selectedAllergicIngredientIds
          ..clear()
          ..addAll(
            savedFilters.allergicIngredientIds.where(validIngredientIds.contains),
          );
      } else {
        _maxPrice = _sliderMaxPrice;
        _selectedAllergicIngredientIds.clear();
      }
    });
  }

  Future<void> _confirmAndRecommend() async {
    final SheetData? data = _sheetData;
    if (data == null || data.foods.isEmpty) {
      setState(() => _feedback = 'Chưa có dữ liệu món ăn để lọc.');
      return;
    }

    final SavedFilters filters = SavedFilters(
      mealId: _selectedMealId,
      maxPriceVnd: _maxPrice.round(),
      allergicIngredientIds: _selectedAllergicIngredientIds.toList()..sort(),
    );

    await _storageService.save(filters);
    final SavedFilters? savedFilterFromFile = await _storageService.read();
    if (!mounted) {
      return;
    }
    if (savedFilterFromFile == null) {
      setState(() => _feedback = 'Không đọc lại được bộ lọc vừa lưu.');
      return;
    }

    final List<Food> matches = _filterFoods(data.foods, savedFilterFromFile);
    widget.onFoodsFiltered(matches);
    setState(() {
      if (matches.isEmpty) {
        _feedback = 'Không có món phù hợp — thử nới giá hoặc bỏ dị ứng.';
        return;
      }

      final Food previewFood = matches[Random().nextInt(matches.length)];
      _feedback = '${matches.length} món phù hợp (ví dụ: ${previewFood.name}).';
    });

    if (matches.isNotEmpty) {
      widget.onOpenWheelRequested();
    }
  }

  List<Food> _filterFoods(List<Food> foods, SavedFilters filters) {
    return foods.where((Food food) {
      if (filters.mealId != null && !food.mealId.contains(filters.mealId!)) {
        return false;
      }

      if (food.priceVnd > filters.maxPriceVnd) {
        return false;
      }

      if (filters.allergicIngredientIds.isNotEmpty) {
        final bool hasAllergyIngredient = food.ingredientIds.any(
          (String ingredientId) => filters.allergicIngredientIds.contains(ingredientId),
        );
        return !hasAllergyIngredient;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final SheetData? data = _sheetData;
    if (_isLoading || data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Meal> meals = data.meals;
    final List<Ingredient> ingredients = data.ingredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                GradientText('Chọn bữa ăn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedMealId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả bữa ăn'),
                    ),
                    ...meals.map(
                      (Meal meal) => DropdownMenuItem<String?>(
                        value: meal.id,
                        child: Text(meal.name),
                      ),
                    ),
                  ],
                  onChanged: (String? value) => setState(() => _selectedMealId = value),
                ),
                const SizedBox(height: 16),
                GradientText(
                  'Giới hạn thiệt hại mỗi người: ${CommonService.toLocalString(_maxPrice.round())} VND',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Slider(
                  value: _maxPrice.clamp(_sliderMinPrice, _sliderMaxPrice),
                  min: _sliderMinPrice,
                  max: _sliderMaxPrice,
                  label: CommonService.toLocalString(_maxPrice.round()),
                  onChanged: (double value) => setState(() => _maxPrice = value),
                ),
                const SizedBox(height: 8),
                GradientText(
                  'Thành phần dị ứng',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                MultiDropdown<String>(
                  items: ingredients
                      .map(
                        (Ingredient ingredient) => DropdownItem<String>(
                          value: ingredient.id,
                          label: ingredient.name,
                          selected: _selectedAllergicIngredientIds.contains(ingredient.id),
                        ),
                      )
                      .toList(),
                  fieldDecoration: const FieldDecoration(
                    hintText: 'Chọn thành phần dị ứng',
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  searchEnabled: true,
                  searchDecoration: const SearchFieldDecoration(
                    hintText: 'Tìm thành phần dị ứng',
                  ),
                  onSelectionChange: (List<String> values) {
                    _selectedAllergicIngredientIds
                      ..clear()
                      ..addAll(values);
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: _confirmAndRecommend,
              icon: const Icon(Icons.auto_awesome_rounded),
              child: const Text('Giờ đến phần GAY cấn nhất nào'),
            ),
          ),
        ),
      ],
    );
  }
}
