import 'dart:math';

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../models/ingredient.dart';
import '../models/meal.dart';
import '../models/saved_filters.dart';
import '../models/sheet_data.dart';
import '../services/filter_storage_service.dart';
import '../services/google_sheet_service.dart';

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
  int? _selectedMealId;
  double _maxPrice = 70000;
  double _sliderMinPrice = 10000;
  double _sliderMaxPrice = 300000;
  final Set<int> _allergicIngredientIds = <int>{};

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
    if (!GoogleSheetService.hasSessionCache) {
      setState(() {
        _isLoading = true;
        _feedback = null;
      });
    } else {
      setState(() => _feedback = null);
    }

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
        _allergicIngredientIds
          ..clear()
          ..addAll(savedFilters.allergicIngredientIds);
      } else {
        _maxPrice = _sliderMaxPrice;
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
      allergicIngredientIds: _allergicIngredientIds.toList()..sort(),
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
      if (filters.mealId != null && food.mealId != filters.mealId) {
        return false;
      }

      if (food.priceVnd > filters.maxPriceVnd) {
        return false;
      }

      if (filters.allergicIngredientIds.isNotEmpty) {
        final bool hasAllergyIngredient = food.ingredientIds.any(
          (int ingredientId) => filters.allergicIngredientIds.contains(ingredientId),
        );
        return !hasAllergyIngredient;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final SheetData? data = _sheetData;
    final List<Meal> meals = data?.meals ?? <Meal>[];
    final List<Ingredient> ingredients = data?.ingredients ?? <Ingredient>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<int?>(
                  initialValue: _selectedMealId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Chọn bữa ăn',
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả bữa ăn'),
                    ),
                    ...meals.map(
                      (Meal meal) => DropdownMenuItem<int?>(
                        value: meal.id,
                        child: Text(meal.name),
                      ),
                    ),
                  ],
                  onChanged: (int? value) => setState(() => _selectedMealId = value),
                ),
                const SizedBox(height: 16),
                Text('Giá tối đa: ${_maxPrice.round()} VND'),
                Slider(
                  value: _maxPrice.clamp(_sliderMinPrice, _sliderMaxPrice),
                  min: _sliderMinPrice,
                  max: _sliderMaxPrice,
                  label: _maxPrice.round().toString(),
                  onChanged: (double value) => setState(() => _maxPrice = value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thành phần dị ứng',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ingredients.map((Ingredient ingredient) {
                    final bool selected = _allergicIngredientIds.contains(ingredient.id);
                    return FilterChip(
                      label: Text(ingredient.name),
                      selected: selected,
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _allergicIngredientIds.add(ingredient.id);
                          } else {
                            _allergicIngredientIds.remove(ingredient.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _feedback!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirmAndRecommend,
              child: const Text('Xác nhận bộ lọc và chuyển sang vòng quay'),
            ),
          ),
        ),
      ],
    );
  }
}
