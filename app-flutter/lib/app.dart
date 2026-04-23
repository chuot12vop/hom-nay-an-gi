import 'package:flutter/material.dart';

import 'screens/base_home_page.dart';
import 'services/user_location_service.dart';
import 'theme/app_theme.dart';

class HomNayAnGiApp extends StatefulWidget {
  const HomNayAnGiApp({super.key});

  @override
  State<HomNayAnGiApp> createState() => _HomNayAnGiAppState();
}

class _HomNayAnGiAppState extends State<HomNayAnGiApp>
    with WidgetsBindingObserver {
  final UserLocationService _userLocationService = UserLocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _captureLocation();
    }
  }

  void _captureLocation() {
    _userLocationService.refreshAndPersist().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hôm Nay Ăn Gì',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const BaseHomePage(),
    );
  }
}
