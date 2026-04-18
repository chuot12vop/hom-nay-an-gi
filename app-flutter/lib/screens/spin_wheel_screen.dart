import 'dart:math';

import 'package:flutter/material.dart';

import '../models/food.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({
    required this.foods,
    super.key,
  });

  final List<Food> foods;

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
  int? _pendingWinnerIndex;
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

  void _spin() {
    final List<Food> foods = widget.foods;
    if (_isSpinning || foods.isEmpty) {
      return;
    }

    final int winnerIndex = Random().nextInt(foods.length);
    final double sweep = (2 * pi) / foods.length;
    final double stopRotation = -(winnerIndex * sweep + (sweep / 2));
    _pendingTargetRotation = _currentRotation + (2 * pi * 5) + stopRotation;

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: _pendingTargetRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    setState(() {
      _isSpinning = true;
      _winner = null;
      _pendingWinnerIndex = winnerIndex;
    });

    _controller
      ..reset()
      ..forward();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    final int? winnerIndex = _pendingWinnerIndex;
    if (winnerIndex == null || winnerIndex >= widget.foods.length) {
      return;
    }
    setState(() {
      _isSpinning = false;
      _currentRotation = _pendingTargetRotation % (2 * pi);
      _winner = widget.foods[winnerIndex];
      _pendingWinnerIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Food> foods = widget.foods;
    if (foods.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có món để quay.\nHãy vào tab Chọn món và xác nhận bộ lọc trước.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          const Text(
            'Hãy để tôi quyết định số phận của bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 280,
                height: 280,
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
                            painter: _WheelPainter(foods: foods),
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
                    Material(
                      elevation: 6,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).colorScheme.primary,
                      child: InkWell(
                        onTap: _isSpinning ? null : _spin,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: Center(
                            child: _isSpinning
                                ? SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.casino,
                                        size: 30,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quay',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_winner != null)
            Text(
              'Nhân phẩm của bạn đã đặt niềm tin ở ${_winner!.name}. \nLet us go!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.foods});

  final List<Food> foods;
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
          style: const TextStyle(
            color: Colors.black87,
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
    return oldDelegate.foods != foods;
  }
}
