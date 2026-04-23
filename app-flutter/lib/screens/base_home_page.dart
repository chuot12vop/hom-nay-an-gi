import 'package:flutter/material.dart';

import '../controllers/base_home_controller.dart';
import '../models/food.dart';
import '../widgets/base_home_shell.dart';
import 'history_screen.dart';
import 'restaurant_list_screen.dart';
import 'short_videos_screen.dart';
import 'spin_wheel_screen.dart';

class BaseHomePage extends StatefulWidget {
  const BaseHomePage({super.key});

  @override
  State<BaseHomePage> createState() => _BaseHomePageState();
}

class _BaseHomePageState extends State<BaseHomePage> {
  late final BaseHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BaseHomeController()..addListener(_onControllerChanged);
    _controller.loadDefaultWheelFoods();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTabBody() {
    final Widget accountPlaceholder = Center(
      child: Text(
        'Nội dung tạm thời để trống',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );

    final List<Food> wheelFoods = _controller.filteredFoods.isNotEmpty
        ? _controller.filteredFoods
        : _controller.defaultWheelFoods;

    return IndexedStack(
      index: _controller.selectedIndex,
      children: <Widget>[
        HistoryScreen(key: ValueKey<int>(_controller.historyVersion)),
        const RestaurantListScreen(),
        SpinWheelScreen(
          key: ValueKey<int>(_controller.wheelSession),
          foods: wheelFoods,
          isLoadingDefaultFoods: _controller.filteredFoods.isEmpty &&
              _controller.defaultWheelLoading,
          onSpinCompleted: _controller.handleSpinCompleted,
          onNavigateToChooseFood: _controller.navigateToChooseFoodFromWheel,
        ),
        ShortVideosScreen(isActiveTab: _controller.selectedIndex == 3),
        accountPlaceholder,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseHomeShell(
      currentIndex: _controller.selectedIndex,
      onNavTap: _controller.onNavItemTapped,
      body: _buildTabBody(),
    );
  }
}
