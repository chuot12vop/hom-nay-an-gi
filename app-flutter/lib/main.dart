import 'package:flutter/material.dart';

import 'models/food.dart';
import 'screens/choose_food_screen.dart';
import 'screens/spin_wheel_screen.dart';

void main() {
  runApp(const HomNayAnGiApp());
}

class HomNayAnGiApp extends StatelessWidget {
  const HomNayAnGiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hôm Nay Ăn Gì',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return ChooseFoodScreen(
          onFoodsFiltered: (List<Food> foods) {
            setState(() => _filteredFoods = foods);
          },
          onOpenWheelRequested: () {
            setState(() => _selectedIndex = 2);
          },
        );
      case 2:
        return SpinWheelScreen(foods: _filteredFoods);
      default:
        return Center(
          child: Text(
            'Nội dung tạm thời để trống',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: <Widget>[
            CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage('assets/image/logoApp.png'),
              backgroundColor: Colors.transparent,
            ),
            SizedBox(width: 10),
            Text('Hôm Nay Ăn Gì'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Chọn món',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino_outlined),
            label: 'Vòng quay',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            label: 'Short video',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
