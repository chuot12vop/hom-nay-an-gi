import 'package:flutter/material.dart';

/// Bảng màu + gradient dùng chung cho toàn app.
///
/// Tông chủ đạo: cam → hồng → đỏ.
class AppGradients {
  const AppGradients._();

  static const Color primaryStart = Color(0xFFFFB347); // cam nhạt
  static const Color primaryOrange = Color(0xFFFF7A59); // cam
  static const Color primaryMid = Color(0xFFFF4E8C); // hồng
  static const Color primaryEnd = Color(0xFFFF2D55); // đỏ

  /// Nền nhẹ / surface
  static const Color surfaceTint = Color(0xFFFFF3EE);

  /// Gradient chính (chéo) dùng cho nút, highlight, nút tròn navbar.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryStart, primaryOrange, primaryMid, primaryEnd],
    stops: <double>[0.0, 0.35, 0.7, 1.0],
  );

  /// Gradient ngang cho AppBar / banner.
  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[primaryStart, primaryOrange, primaryMid, primaryEnd],
    stops: <double>[0.0, 0.35, 0.7, 1.0],
  );

  /// Gradient nhạt cho nền / card.
  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFF6F0), Color(0xFFFFFFFF)],
  );
}
