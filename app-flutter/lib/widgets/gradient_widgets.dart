import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

/// Text đổ gradient cam-hồng-đỏ.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    this.style,
    this.textAlign,
    this.gradient,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Gradient? gradient;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final Gradient g = gradient ?? AppGradients.primary;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => g.createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Nút bấm nền gradient cam-hồng-đỏ, bo tròn, có shadow hồng nhẹ.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 52,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.gradient,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Gradient g = gradient ?? AppGradients.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppGradients.primaryMid.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      IconTheme(
                        data: const IconThemeData(color: Colors.white, size: 20),
                        child: icon!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar có nền gradient cam-hồng-đỏ (thay cho AppBar mặc định).
///
/// Dùng `flexibleSpace` để gradient phủ cả vùng status bar.
class GradientAppBar extends AppBar {
  GradientAppBar({
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    super.key,
  }) : super(
          title: title,
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.primaryHorizontal,
            ),
          ),
        );
}
