import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Thanh điều hướng dưới cùng:
/// - 4 mục thường (Lịch sử / Quán ăn / Video / Tài khoản)
/// - 1 nút tròn nổi ở giữa (vòng quay) với gradient cam-hồng-đỏ.
/// - Mục được chọn: icon + chữ đổ gradient cam-hồng-đỏ.
class AppGradientBottomNav extends StatelessWidget {
  const AppGradientBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerIndex = 2,
    super.key,
  }) : assert(items.length == 5, 'AppGradientBottomNav cần đúng 5 items');

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;
  final int centerIndex;

  @override
  Widget build(BuildContext context) {
    const double barHeight = 74;
    const double centerButtonSize = 64;
    const double centerLift = 20;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, centerLift, 12, 10),
        child: SizedBox(
          height: barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List<Widget>.generate(items.length, (int index) {
                      if (index == centerIndex) {
                        return const SizedBox(width: centerButtonSize + 16);
                      }
                      return Expanded(
                        child: _NavItem(
                          item: items[index],
                          selected: currentIndex == index,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                top: -centerLift,
                child: _CenterButton(
                  item: items[centerIndex],
                  selected: currentIndex == centerIndex,
                  onTap: () => onTap(centerIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color inactiveColor = Color(0xFF8A8A8E);

    final Widget icon = Icon(
      selected ? item.activeIcon : item.icon,
      size: 24,
      color: selected ? Colors.white : inactiveColor,
    );

    final Widget label = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? Colors.white : inactiveColor,
      ),
    );

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        icon,
        const SizedBox(height: 4),
        label,
      ],
    );

    if (selected) {
      content = ShaderMask(
        shaderCallback: (Rect bounds) =>
            AppGradients.primary.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppGradients.primaryMid.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppGradients.primaryEnd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
