import 'package:flutter/material.dart';

import 'models/food.dart';
import 'models/sheet_data.dart';
import 'screens/choose_food_screen.dart';
import 'screens/history_screen.dart';
import 'screens/short_videos_screen.dart';
import 'screens/spin_wheel_screen.dart';
import 'services/google_sheet_service.dart';
import 'services/spin_history_service.dart';
import 'theme/app_gradients.dart';
import 'widgets/app_gradient_bottom_nav.dart';
import 'widgets/gradient_widgets.dart';

void main() {
  runApp(const HomNayAnGiApp());
}

class HomNayAnGiApp extends StatelessWidget {
  const HomNayAnGiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppGradients.primaryMid,
      primary: AppGradients.primaryEnd,
      secondary: AppGradients.primaryOrange,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'Hôm Nay Ăn Gì',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFFFF8F4),
        useMaterial3: true,

        sliderTheme: SliderThemeData(
          activeTrackColor: AppGradients.primaryEnd,
          inactiveTrackColor: AppGradients.primaryStart.withValues(alpha: 0.3),
          thumbColor: AppGradients.primaryMid,
          overlayColor: AppGradients.primaryMid.withValues(alpha: 0.2),
          valueIndicatorColor: AppGradients.primaryEnd,
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: AppGradients.primaryMid,
          checkmarkColor: Colors.white,
          labelStyle: const TextStyle(color: Color(0xFF5A5A5E)),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: AppGradients.primaryStart.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppGradients.primaryStart.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppGradients.primaryStart.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppGradients.primaryMid,
              width: 1.6,
            ),
          ),
          labelStyle: const TextStyle(color: Color(0xFF5A5A5E)),
          floatingLabelStyle: const TextStyle(color: AppGradients.primaryEnd),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppGradients.primaryEnd,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppGradients.primaryEnd,
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppGradients.primaryMid,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const BaseHomePage(),
    );
  }
}

class BaseHomePage extends StatefulWidget {
  const BaseHomePage({super.key});

  @override
  State<BaseHomePage> createState() => _BaseHomePageState();
}

class _BaseHomePageState extends State<BaseHomePage> {
  int _selectedIndex = 1;
  List<Food> _filteredFoods = <Food>[];
  int _wheelSession = 0;

  /// Khi chưa lọc từ Gọi món: tối đa 10 món khác nhau từ lịch sử quay gần nhất.
  List<Food> _defaultWheelFoods = <Food>[];
  bool _defaultWheelLoading = true;
  int _historyVersion = 0;

  final SpinHistoryService _spinHistoryService = SpinHistoryService();

  @override
  void initState() {
    super.initState();
    _loadDefaultWheelFoods();
  }

  /// [silent]: sau khi quay — chỉ cập nhật danh sách, không bật loading che vòng quay.
  Future<void> _loadDefaultWheelFoods({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _defaultWheelLoading = true;
      });
    }
    try {
      final GoogleSheetService sheet = GoogleSheetService();
      final SheetData data = await sheet.fetchAllTables();
      final List<String> ids = await _spinHistoryService.recentUniqueFoodIds(10);
      final List<Food> foods = _foodsFromIds(ids, data.foods);
      if (!mounted) {
        return;
      }
      setState(() {
        _defaultWheelFoods = foods;
        _defaultWheelLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _defaultWheelFoods = <Food>[];
        _defaultWheelLoading = false;
      });
    }
  }

  List<Food> _foodsFromIds(List<String> ids, List<Food> allFoods) {
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

  Future<void> _handleSpinCompleted(Food food) async {
    await _spinHistoryService.appendSpin(food);
    if (!mounted) {
      return;
    }
    setState(() {
      _historyVersion++;
    });
    await _loadDefaultWheelFoods(silent: true);
  }

  /// Rời tab Vòng quay: xóa món đã lọc + tạo lại state vòng quay (winner, góc quay…).
  void _clearWheelAndFoods() {
    _filteredFoods = <Food>[];
    _wheelSession++;
  }

  void _onItemTapped(int index) {
    setState(() {
      if (_selectedIndex == 2 && index != 2) {
        _clearWheelAndFoods();
      }
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    final Widget accountPlaceholder = Center(
      child: Text(
        'Nội dung tạm thời để trống',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );

    final List<Food> wheelFoods =
        _filteredFoods.isNotEmpty ? _filteredFoods : _defaultWheelFoods;

    return IndexedStack(
      index: _selectedIndex,
      children: <Widget>[
        HistoryScreen(key: ValueKey<int>(_historyVersion)),
        ChooseFoodScreen(
          onFoodsFiltered: (List<Food> foods) {
            setState(() => _filteredFoods = foods);
          },
          onOpenWheelRequested: () {
            setState(() => _selectedIndex = 2);
          },
        ),
        SpinWheelScreen(
          key: ValueKey<int>(_wheelSession),
          foods: wheelFoods,
          isLoadingDefaultFoods:
              _filteredFoods.isEmpty && _defaultWheelLoading,
          onSpinCompleted: _handleSpinCompleted,
          onNavigateToChooseFood: () => setState(() {
            _selectedIndex = 1;
            _clearWheelAndFoods();
          }),
        ),
        ShortVideosScreen(isActiveTab: _selectedIndex == 3),
        accountPlaceholder,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Row(
          children: <Widget>[
            CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage('assets/image/logoApp.png'),
              backgroundColor: Colors.white,
            ),
            SizedBox(width: 10),
            GradientText('Hôm Nay Ăn Gì'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppGradients.primaryMid.withValues(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: AppGradientBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <AppBottomNavItem>[
          AppBottomNavItem(
            icon: Icons.history,
            activeIcon: Icons.history,
            label: 'Lịch sử',
          ),
          AppBottomNavItem(
            icon: Icons.restaurant_menu,
            activeIcon: Icons.restaurant_menu,
            label: 'Gọi món',
          ),
          AppBottomNavItem(
            icon: Icons.casino_outlined,
            activeIcon: Icons.casino,
            label: 'Vòng quay',
          ),
          AppBottomNavItem(
            icon: Icons.videocam_outlined,
            activeIcon: Icons.videocam,
            label: 'Video',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
