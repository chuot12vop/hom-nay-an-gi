import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/shared_restaurant.dart';

/// Lưu danh sách quán ăn người dùng chia sẻ vào thư mục documents cục bộ.
class RestaurantStorageService {
  RestaurantStorageService({String fileName = 'shared_restaurants.json'})
      : _fileName = fileName;

  final String _fileName;

  Future<List<SharedRestaurant>> readAll() async {
    final File file = await _file();
    if (!await file.exists()) {
      return <SharedRestaurant>[];
    }
    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <SharedRestaurant>[];
    }
    final List<dynamic> list = jsonDecode(content) as List<dynamic>;
    return list
        .map((dynamic e) =>
            SharedRestaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(SharedRestaurant restaurant) async {
    final List<SharedRestaurant> current = await readAll();
    current.insert(0, restaurant);
    await _writeAll(current);
  }

  Future<void> delete(String id) async {
    final List<SharedRestaurant> current = await readAll();
    current.removeWhere((SharedRestaurant r) => r.id == id);
    await _writeAll(current);
  }

  Future<void> _writeAll(List<SharedRestaurant> items) async {
    final File file = await _file();
    final String raw = jsonEncode(
      items.map((SharedRestaurant r) => r.toJson()).toList(),
    );
    await file.writeAsString(raw);
  }

  Future<File> _file() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
