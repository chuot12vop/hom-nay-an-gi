import 'dart:math';

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';
import 'food_detail_screen.dart';
import 'restaurant_list_screen.dart';

/// Trùng logic WebView công thức trong [FoodDetailScreen]: chỉ coi là có công thức khi URL http(s) hợp lệ.
bool _foodHasRecipeUrl(Food food) {
  final String? raw = food.recipeUrl;
  if (raw == null || raw.trim().isEmpty) {
    return false;
  }
  final Uri? uri = Uri.tryParse(raw.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({
    required this.foods,
    required this.onNavigateToChooseFood,
    this.onSpinCompleted,
    this.isLoadingDefaultFoods = false,
    super.key,
  });

  final List<Food> foods;
  final VoidCallback onNavigateToChooseFood;

  /// Gọi khi vòng quay dừng và đã xác định món trúng (để lưu lịch sử).
  final ValueChanged<Food>? onSpinCompleted;

  /// Đang tải 10 món mặc định từ lịch sử (khi chưa lọc từ Gọi món).
  final bool isLoadingDefaultFoods;

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _rotationAnimation;
  double _currentRotation = 0;
  Food? _winner;
  bool _isSpinning = false;
  double _pendingTargetRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Đưa góc về [0, 2π).
  static double _normalize2Pi(double radians) {
    double t = radians % (2 * pi);
    if (t < 0) {
      t += 2 * pi;
    }
    return t;
  }

  /// Món nằm dưới mũi tên (12h) khi bánh đã quay [rotationRad] (cùng chiều Transform.rotate).
  int _indexUnderPointer(double rotationRad) {
    final int n = widget.foods.length;
    if (n == 0) {
      return 0;
    }
    final double sweep = (2 * pi) / n;
    // Offset từ mép ô 0: t = -rotationRad (mod 2π)
    final double t = _normalize2Pi(-rotationRad);
    final int i = (t / sweep).floor().clamp(0, n - 1);
    return i;
  }

  void _spin() {
    final List<Food> foods = widget.foods;
    if (_isSpinning || foods.isEmpty) {
      return;
    }

    final int winnerIndex = Random().nextInt(foods.length);
    final double sweep = (2 * pi) / foods.length;
    // Cần mid_winner + góc đích ≡ -π/2 (mod 2π) → góc đích ≡ -π/2 - mid_winner (mod 2π)
    final double midWinner = -pi / 2 + winnerIndex * sweep + sweep / 2;
    final double targetMod = _normalize2Pi(-pi / 2 - midWinner);
    final double currentMod = _normalize2Pi(_currentRotation);
    final double diff = (targetMod - currentMod + 2 * pi) % (2 * pi);
    _pendingTargetRotation = _currentRotation + (2 * pi * 5) + diff;

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: _pendingTargetRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    _controller
      ..reset()
      ..forward();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    if (widget.foods.isEmpty) {
      return;
    }
    final double rotation = _normalize2Pi(_pendingTargetRotation);
    final int underPointer = _indexUnderPointer(rotation);
    final Food winner = widget.foods[underPointer];
    setState(() {
      _isSpinning = false;
      _currentRotation = rotation;
      _winner = winner;
    });
    widget.onSpinCompleted?.call(winner);
  }

  Future<void> _showConfirmThen(String message, VoidCallback onConfirmed) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirmed();
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Food> foods = widget.foods;
    final Color labelColor = AppGradients.primaryMid;
    if (foods.isEmpty) {
      if (widget.isLoadingDefaultFoods) {
        return Center(
          child: CircularProgressIndicator(color: AppGradients.primaryMid),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GradientText(
            'Chưa có món để quay.\nHãy vào tab Gọi món và xác nhận bộ lọc',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          GradientText(
            _winner != null ? 'Bạn đã tìm được DESTINY rồi đấy =)) \n Bạn sẽ làm gì tiếp theo?' : 'Hãy để tôi định đoạt số phận bạn',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _winner != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            GradientButton(
                              onPressed: () => _showConfirmThen(
                                'Bạn muốn quay xe và chọn lại từ đầu',
                                widget.onNavigateToChooseFood,
                              ),
                              icon: const Icon(Icons.u_turn_left_rounded),
                              child: const Text('Quay xe'),
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              onPressed: () => _showConfirmThen(
                                'Hay đấy! lẹttt gâuuu!',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (BuildContext _) =>
                                          const RestaurantListScreen(),
                                    ),
                                  );
                                },
                              ),
                              icon: const Icon(Icons.storefront_outlined),
                              child: const Text('Đi ăn ngoài'),
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              onPressed: () => _showConfirmThen(
                                'Có vẻ bạn hơi lười... nhưng tôi thích điều đó',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (BuildContext _) =>
                                          const RestaurantListScreen(),
                                    ),
                                  );
                                },
                              ),
                              icon: const Icon(Icons.delivery_dining),
                              child: const Text('Đặt đồ về ăn tại nhà'),
                            ),
                            if (_foodHasRecipeUrl(_winner!)) ...<Widget>[
                              const SizedBox(height: 12),
                              GradientButton(
                                onPressed: () {
                                  final Food dish = _winner!;
                                  _showConfirmThen(
                                    'Khét đấy nhể !!! để tôi giúp bạn một bước tới con đường thành công nhé !!',
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext _) =>
                                              FoodDetailScreen(food: dish),
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.restaurant_rounded),
                                child: const Text('Tự nấu'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isSpinning ? null : _spin,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (BuildContext context, Widget? child) {
                                final double angle =
                                    _rotationAnimation?.value ?? _currentRotation;
                                return Transform.rotate(
                                  angle: angle,
                                  child: CustomPaint(
                                    size: const Size.square(280),
                                    painter: _WheelPainter(
                                      foods: foods,
                                      labelColor: labelColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Positioned(
                              top: 0,
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 44,
                                color: Colors.redAccent,
                              ),
                            ),
                            if (_isSpinning)
                              Center(
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppGradients.primaryMid,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // nếu có winner thì hiển thị nhân phẩm, nếu không thì hiển thị đợi quay
          
          GradientText(
            _winner != null
                ? 'Nhân phẩm của bạn đã đặt niềm tin ở \n${_winner!.name}!'
                : 'Để xem nhân phẩm đến đâu nào \n ...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.foods, required this.labelColor});

  final List<Food> foods;
  final Color labelColor;
  final List<Color> _palette = <Color>[
    const Color(0xFFFFCC80),
    const Color(0xFF80DEEA),
    const Color(0xFFC5E1A5),
    const Color(0xFFFFAB91),
    const Color(0xFFB39DDB),
    const Color(0xFFFFF59D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2;
    final double sweep = (2 * pi) / foods.length;

    for (int i = 0; i < foods.length; i++) {
      final Paint paint = Paint()
        ..color = _palette[i % _palette.length]
        ..style = PaintingStyle.fill;
      final double startAngle = -pi / 2 + (i * sweep);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      final double textAngle = startAngle + (sweep / 2);
      final Offset textOffset = Offset(
        center.dx + cos(textAngle) * radius * 0.6,
        center.dy + sin(textAngle) * radius * 0.6,
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: foods[i].name,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        ellipsis: '...',
      )..layout(maxWidth: radius * 0.8);

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    final Paint border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, border);
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.foods != foods || oldDelegate.labelColor != labelColor;
  }
}
