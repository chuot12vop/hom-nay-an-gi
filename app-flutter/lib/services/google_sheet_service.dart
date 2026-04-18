import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

import '../models/food.dart';
import '../models/ingredient.dart';
import '../models/meal.dart';
import '../models/sheet_data.dart';

class GoogleSheetService {
  static const String defaultSheetId = '1VoJ-5oiBt0YKPuAwUFDKaleNS8OofHGEed5Rurmoscc';
  static const String foodsGid = '93052399';
  static const String categoriesGid = '2072471033';
  static const String ingredientsGid = '1896529337';
  static const String mealsGid = '1084511461';
  static const String videosGid = '974384037';

  /// Dữ liệu sheet đã tải trong phiên app (một lần cho mọi [GoogleSheetService]).
  static SheetData? _sessionCache;
  static Future<SheetData>? _loadInFlight;

  /// `true` khi đã có dữ liệu trong bộ nhớ (không gọi mạng lại).
  static bool get hasSessionCache => _sessionCache != null;

  /// Trả về dữ liệu đã cache; chỉ gọi mạng lần đầu (hoặc khi chưa có cache).
  Future<SheetData> fetchAllTables() async {
    final SheetData? cached = _sessionCache;
    if (cached != null) {
      return cached;
    }
    _loadInFlight ??= _fetchAllTablesFromNetwork();
    try {
      final SheetData data = await _loadInFlight!;
      _sessionCache = data;
      return data;
    } catch (_) {
      _loadInFlight = null;
      rethrow;
    }
  }

  Future<SheetData> _fetchAllTablesFromNetwork() async {
    try {
      final List<Map<String, String>> foodsRows = await _fetchCsvRows(
        sheetId: defaultSheetId,
        gid: foodsGid,
      );
      final List<Map<String, String>> ingredientsRows = await _fetchCsvRows(
        sheetId: defaultSheetId,
        gid: ingredientsGid,
      );
      final List<Map<String, String>> mealsRows = await _fetchCsvRows(
        sheetId: defaultSheetId,
        gid: mealsGid,
      );

      return SheetData(
        foods: foodsRows.map(_foodFromRow).toList(),
        ingredients: ingredientsRows.map(_ingredientFromRow).toList(),
        meals: mealsRows.map(_mealFromRow).toList(),
      );
    } catch (_) {
      return _fallbackData();
    }
  }

  /// Google Sheets trả CSV UTF-8 nhưng `http.Response.body` mặc định dùng
  /// [latin1] khi header không có `charset=utf-8` → lỗi kiểu "Phá»Ÿ bÃ²".
  String _decodeCsvBodyUtf8(http.Response response) {
    final List<int> raw = response.bodyBytes;
    if (raw.isEmpty) {
      return '';
    }
    int start = 0;
    if (raw.length >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF) {
      start = 3;
    }
    final List<int> slice = start == 0 ? raw : raw.sublist(start);
    try {
      return utf8.decode(slice);
    } catch (_) {
      return response.body;
    }
  }

  Future<List<Map<String, String>>> _fetchCsvRows({
    required String sheetId,
    required String gid,
  }) async {
    final Uri uri = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv&gid=$gid',
    );
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to read Google Sheet gid=$gid');
    }

    final List<List<dynamic>> csvRows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(_decodeCsvBodyUtf8(response));
    if (csvRows.isEmpty) {
      return <Map<String, String>>[];
    }

    final List<String> headers = csvRows.first
        .map((dynamic value) => value.toString().trim())
        .toList();

    final List<Map<String, String>> mappedRows = <Map<String, String>>[];
    for (final List<dynamic> values in csvRows.skip(1)) {
      if (values.every((dynamic value) => value.toString().trim().isEmpty)) {
        continue;
      }

      final Map<String, String> row = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        final String value = i < values.length ? values[i].toString() : '';
        row[headers[i]] = value.trim();
      }
      mappedRows.add(row);
    }
    return mappedRows;
  }

  Food _foodFromRow(Map<String, String> row) {
    final String id = row['food_id'] ?? '';
    final String categoryId = row['category_ids'] ?? '';
    final String mealId = row['meal_ids'] ?? '';
    final int priceVnd = _toInt(row['price_vnd']) ?? 0;

    final String ingredientIdsText = row['ingredient_ids'] ?? '';
    final List<String> ingredientIds = ingredientIdsText
        .split(',')
        .map((String value) =>value.trim())
        .toList();

    final String? mainIngredientId = row['main_ingredient_id'];
    if (ingredientIds.isEmpty && mainIngredientId != null) {
      ingredientIds.add(mainIngredientId);
    }

    final String imageUrl = (row['image'] ?? row['food_image_url'] ?? '').trim();
    final String recipeUrl = (row['recipe'] ?? '').trim();
    final String youtubeUrl = (row['youtube'] ?? row['video_url'] ?? '').trim();

    return Food(
      id: id,
      name: (row['food_name_vi'] ?? row['name'] ?? '').trim(),
      categoryId: categoryId,
      mealId: mealId,
      priceVnd: priceVnd,
      ingredientIds: ingredientIds,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      recipeUrl: recipeUrl.isEmpty ? null : recipeUrl,
      youtubeUrl: youtubeUrl.isEmpty ? null : youtubeUrl,
    );
  }

  Ingredient _ingredientFromRow(Map<String, String> row) {
    return Ingredient(
      id: row['ingredient_id'] ?? '0',
      name: (row['ingredient_name_vi'] ?? row['name'] ?? '').trim(),
    );
  }

  Meal _mealFromRow(Map<String, String> row) {
    return Meal(
      id: row['meal_id'] ?? '',
      code: (row['meal_code'] ?? '').trim(),
      name: (row['meal_name_vi'] ?? row['name'] ?? '').trim(),
    );
  }

  int? _toInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value.trim());
  }

  SheetData _fallbackData() {
    return const SheetData(
      foods: <Food>[
        Food(
          id: '1',
          name: 'Phở bò',
          categoryId: '1',
          mealId: '2',
          priceVnd: 50000,
          ingredientIds: <String>['3', '7'],
        ),
        Food(
          id: '2',
          name: 'Cơm gà',
          categoryId: '2',
          mealId: '3',
          priceVnd: 55000,
          ingredientIds: <String>['2', '1'],
        ),
        Food(
          id: '3',
          name: 'Đậu hũ sốt cà',
          categoryId: '4',
          mealId: '3',
          priceVnd: 40000,
          ingredientIds: <String>['5', '6'],
        ),
      ],
      ingredients: <Ingredient>[
        Ingredient(id: '1', name: 'Gạo'),
        Ingredient(id: '2', name: 'Thịt gà'),
        Ingredient(id: '3', name: 'Thịt bò'),
        Ingredient(id: '5', name: 'Đậu hũ'),
        Ingredient(id: '6', name: 'Rau cải'),
        Ingredient(id: '7', name: 'Mì'),
      ],
      meals: <Meal>[
        Meal(id: '1', code: 'BREAKFAST', name: 'Bữa sáng'),
        Meal(id: '2', code: 'LUNCH', name: 'Bữa trưa'),
        Meal(id: '3', code: 'DINNER', name: 'Bữa tối'),
      ],
    );
  }
}
