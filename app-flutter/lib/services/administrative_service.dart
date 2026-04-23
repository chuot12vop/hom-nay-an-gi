import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/administrative_division.dart';

/// Đọc `assets/json/dia_chinh_34.json` (danh sách 34 tỉnh/thành hiện hành).
///
/// Cấu trúc JSON gốc:
/// ```
/// [
///   {
///     "<TÊN TỈNH>": "<mã tỉnh>",
///     "wards": [ { "<TÊN PHƯỜNG>": "<mã phường>" }, ... ]
///   }, ...
/// ]
/// ```
class AdministrativeService {
  AdministrativeService({String assetPath = 'assets/json/dia_chinh_34.json'})
      : _assetPath = assetPath;

  final String _assetPath;

  List<Province>? _cache;

  Future<List<Province>> loadProvinces() async {
    final List<Province>? cached = _cache;
    if (cached != null) {
      return cached;
    }

    final String raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> json = jsonDecode(raw) as List<dynamic>;

    final List<Province> provinces = json.map<Province>((dynamic entry) {
      final Map<String, dynamic> map = entry as Map<String, dynamic>;
      final List<dynamic> rawWards =
          (map['wards'] as List<dynamic>? ?? const <dynamic>[]);

      String provinceName = '';
      String provinceCode = '';
      for (final MapEntry<String, dynamic> e in map.entries) {
        if (e.key == 'wards') {
          continue;
        }
        provinceName = e.key;
        provinceCode = e.value.toString();
        break;
      }

      final List<Ward> wards = rawWards
          .map<Ward?>((dynamic w) {
            final Map<String, dynamic> wm = w as Map<String, dynamic>;
            if (wm.isEmpty) {
              return null;
            }
            final MapEntry<String, dynamic> first = wm.entries.first;
            return Ward(code: first.value.toString(), name: first.key);
          })
          .whereType<Ward>()
          .toList();

      wards.sort((Ward a, Ward b) => a.name.compareTo(b.name));

      return Province(code: provinceCode, name: provinceName, wards: wards);
    }).toList();

    provinces.sort((Province a, Province b) => a.name.compareTo(b.name));
    _cache = provinces;
    return provinces;
  }
}
