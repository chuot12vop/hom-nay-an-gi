import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';

/// Danh sách quán ăn — có thể mở rộng sau (API / sheet).
class RestaurantListScreen extends StatelessWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const GradientText('Danh sách quán ăn'),
        backgroundColor: Colors.white,
        foregroundColor: AppGradients.primaryMid,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nội dung danh sách quán sẽ được cập nhật sau.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
