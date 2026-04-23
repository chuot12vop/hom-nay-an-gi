import 'package:flutter/foundation.dart';

import '../models/food.dart';
import '../models/sheet_data.dart';
import '../services/google_sheet_service.dart';
import '../services/spin_history_service.dart';

/// State và luồng điều phối tab / vòng quay / lịch sử — tách khỏi widget để dễ unit test.
class BaseHomeController extends ChangeNotifier {
  BaseHomeController({
    SpinHistoryService? spinHistoryService,
    Future<SheetData> Function()? fetchSheetData,
  })  : _spinHistory = spinHistoryService ?? SpinHistoryService(),
        _fetchSheetData =
            fetchSheetData ?? (() => GoogleSheetService().fetchAllTables());

  final SpinHistoryService _spinHistory;
  final Future<SheetData> Function() _fetchSheetData;

  bool _disposed = false;

  int selectedIndex = 1;
  List<Food> filteredFoods = <Food>[];
  int wheelSession = 0;

  /// Khi chưa lọc từ Gọi món: tối đa 10 món khác nhau từ lịch sử quay gần nhất.
  List<Food> defaultWheelFoods = <Food>[];
  bool defaultWheelLoading = true;
  int historyVersion = 0;

  /// Ánh xạ [ids] sang [Food] theo thứ tự id, bỏ id không tồn tại.
  @visibleForTesting
  static List<Food> foodsFromIds(List<String> ids, List<Food> allFoods) {
    final Map<String, Food> map = <String, Food>{
      for (final Food f in allFoods) f.id: f,
    };
    final List<Food> out = <Food>[];
    for (final String id in ids) {
      final Food? f = map[id];
      if (f != null) {
        out.add(f);
      }
    }
    return out;
  }

  void _clearFilteredAndBumpWheelSession() {
    filteredFoods = <Food>[];
    wheelSession++;
  }

  /// [silent]: sau khi quay — chỉ cập nhật danh sách, không bật loading che vòng quay.
  Future<void> loadDefaultWheelFoods({bool silent = false}) async {
    if (!silent) {
      defaultWheelLoading = true;
      notifyListeners();
    }
    try {
      final SheetData data = await _fetchSheetData();
      if (_disposed) {
        return;
      }
      final List<String> ids = await _spinHistory.recentUniqueFoodIds(10);
      if (_disposed) {
        return;
      }
      defaultWheelFoods = foodsFromIds(ids, data.foods);
      defaultWheelLoading = false;
      notifyListeners();
    } catch (_) {
      if (_disposed) {
        return;
      }
      defaultWheelFoods = <Food>[];
      defaultWheelLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleSpinCompleted(Food food) async {
    await _spinHistory.appendSpin(food);
    if (_disposed) {
      return;
    }
    historyVersion++;
    notifyListeners();
    await loadDefaultWheelFoods(silent: true);
  }

  void onNavItemTapped(int index) {
    if (selectedIndex == 2 && index != 2) {
      _clearFilteredAndBumpWheelSession();
    }
    selectedIndex = index;
    notifyListeners();
  }

  void setFilteredFoods(List<Food> foods) {
    filteredFoods = foods;
    notifyListeners();
  }

  void openWheelTab() {
    selectedIndex = 2;
    notifyListeners();
  }

  void navigateToChooseFoodFromWheel() {
    selectedIndex = 1;
    _clearFilteredAndBumpWheelSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
