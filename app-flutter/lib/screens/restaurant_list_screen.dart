import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shared_restaurant.dart';
import '../services/restaurant_storage_service.dart';
import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';
import 'share_restaurant_screen.dart';

/// Tab "Quán ăn": hiển thị danh sách quán do người dùng chia sẻ và
/// nút nổi để mở form chia sẻ quán mới.
class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final RestaurantStorageService _storage = RestaurantStorageService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<SharedRestaurant> _items = <SharedRestaurant>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final List<SharedRestaurant> items = await _storage.readAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openShareForm() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ShareRestaurantScreen(),
      ),
    );
    if (created == true) {
      await _reload();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chia sẻ quán ăn mới!')),
      );
    }
  }

  Future<void> _confirmDelete(SharedRestaurant item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Xoá quán'),
        content: Text('Bạn chắc chắn muốn xoá "${item.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.delete(item.id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          _EmptyState(onShare: _openShareForm)
        else
          RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final SharedRestaurant item = _items[index];
                return _RestaurantCard(
                  item: item,
                  dateLabel: _dateFormat.format(item.createdAt),
                  onLongPress: () => _confirmDelete(item),
                );
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'share_restaurant_fab',
            onPressed: _openShareForm,
            backgroundColor: AppGradients.primaryMid,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Chia sẻ quán'),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.restaurant_rounded,
              size: 72,
              color: AppGradients.primaryOrange,
            ),
            const SizedBox(height: 16),
            GradientText(
              'Chưa có quán ăn nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chia sẻ một quán ăn ngon bạn biết để mọi người cùng thưởng thức!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),            
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.item,
    required this.dateLabel,
    required this.onLongPress,
  });

  final SharedRestaurant item;
  final String dateLabel;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: GradientText(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.foodNames.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.foodNames
                    .map(
                      (String name) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppGradients.surfaceTint,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                AppGradients.primaryMid.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppGradients.primaryEnd,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.place_rounded,
                    size: 18, color: AppGradients.primaryEnd),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.fullAddress,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Icon(Icons.my_location,
                    size: 16, color: AppGradients.primaryMid),
                const SizedBox(width: 4),
                Text(
                  '${item.latitude.toStringAsFixed(5)}, '
                  '${item.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
