import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/food.dart';

/// Lưu các lần quay trúng món (mới nhất trước) — file JSON trong thư mục app.
class SpinHistoryService {
  static const int _maxStoredSpins = 500;

  Future<File> _file() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/spin_history.json');
  }

  Future<List<Map<String, dynamic>>> _readSpins() async {
    final File f = await _file();
    if (!await f.exists()) {
      return <Map<String, dynamic>>[];
    }
    try {
      final Object? decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return <Map<String, dynamic>>[];
      }
      final Object? spins = decoded['spins'];
      if (spins is! List<dynamic>) {
        return <Map<String, dynamic>>[];
      }
      return spins.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeSpins(List<Map<String, dynamic>> spins) async {
    final File f = await _file();
    await f.writeAsString(jsonEncode(<String, dynamic>{'spins': spins}));
  }

  /// Ghi nhận một lần quay trúng (chèn đầu danh sách).
  Future<void> appendSpin(Food food) async {
    final List<Map<String, dynamic>> list = await _readSpins();
    list.insert(0, <String, dynamic>{
      'foodId': food.id,
      'foodName': food.name,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    if (list.length > _maxStoredSpins) {
      list.removeRange(_maxStoredSpins, list.length);
    }
    await _writeSpins(list);
  }

  /// Các lần quay mới nhất trước (để hiển thị Lịch sử).
  Future<List<Map<String, dynamic>>> spinsNewestFirst() async {
    return _readSpins();
  }

  /// Tối đa [limit] `food_id` khác nhau, ưu tiên lần quay gần nhất (không trùng).
  Future<List<String>> recentUniqueFoodIds(int limit) async {
    final List<Map<String, dynamic>> list = await _readSpins();
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final Map<String, dynamic> e in list) {
      final String id = (e['foodId'] as String? ?? '').trim();
      if (id.isEmpty || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      out.add(id);
      if (out.length >= limit) {
        break;
      }
    }
    return out;
  }
}
