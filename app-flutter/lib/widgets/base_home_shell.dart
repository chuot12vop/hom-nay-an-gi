import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import 'app_gradient_bottom_nav.dart';
import 'gradient_widgets.dart';

/// Khung Scaffold: AppBar gradient + bottom nav — tách khỏi state điều phối tab.
class BaseHomeShell extends StatelessWidget {
  const BaseHomeShell({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.body,
  });

  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final Widget body;

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
      body: body,
      bottomNavigationBar: AppGradientBottomNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
        items: const <AppBottomNavItem>[
          AppBottomNavItem(
            icon: Icons.history,
            activeIcon: Icons.history,
            label: 'Lịch sử',
          ),
          AppBottomNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            label: 'Quán ăn',
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
