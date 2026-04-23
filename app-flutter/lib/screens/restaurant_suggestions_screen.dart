import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/food.dart';
import '../models/shared_restaurant.dart';
import '../services/restaurant_storage_service.dart';
import '../services/user_location_service.dart';
import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';
import 'share_restaurant_screen.dart';

/// Gợi ý quán ăn phục vụ [food], sắp theo khoảng cách tới vị trí người dùng.
class RestaurantSuggestionsScreen extends StatefulWidget {
  const RestaurantSuggestionsScreen({
    super.key,
    required this.food,
  });

  final Food food;

  @override
  State<RestaurantSuggestionsScreen> createState() =>
      _RestaurantSuggestionsScreenState();
}

class _RestaurantSuggestionsScreenState
    extends State<RestaurantSuggestionsScreen> {
  final RestaurantStorageService _storage = RestaurantStorageService();
  final UserLocationService _locationService = UserLocationService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<_RankedRestaurant> _items = <_RankedRestaurant>[];
  double? _userLat;
  double? _userLng;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);

    await _resolveUserLocation();
    final List<SharedRestaurant> all = await _storage.readAll();

    final List<SharedRestaurant> matches = all
        .where((SharedRestaurant r) => r.foodIds.contains(widget.food.id))
        .toList();

    final List<_RankedRestaurant> ranked = matches
        .map(
          (SharedRestaurant r) => _RankedRestaurant(
            restaurant: r,
            distanceMeters: _distanceToUser(r),
          ),
        )
        .toList();

    ranked.sort((_RankedRestaurant a, _RankedRestaurant b) {
      // Quán chưa biết khoảng cách (do chưa có vị trí user) → cuối danh sách.
      final double? da = a.distanceMeters;
      final double? db = b.distanceMeters;
      if (da == null && db == null) {
        return 0;
      }
      if (da == null) {
        return 1;
      }
      if (db == null) {
        return -1;
      }
      return da.compareTo(db);
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _items = ranked;
      _loading = false;
    });
  }

  /// Ưu tiên refresh vị trí mới; nếu không có quyền/tắt GPS thì dùng bản lưu gần nhất.
  Future<void> _resolveUserLocation() async {
    try {
      await _locationService.refreshAndPersist();
    } catch (_) {
      // bỏ qua, sẽ fallback bằng readSaved
    }
    final ({double? latitude, double? longitude}) saved =
        await _locationService.readSaved();
    _userLat = saved.latitude;
    _userLng = saved.longitude;
  }

  double? _distanceToUser(SharedRestaurant r) {
    final double? lat = _userLat;
    final double? lng = _userLng;
    if (lat == null || lng == null) {
      return null;
    }
    return Geolocator.distanceBetween(lat, lng, r.latitude, r.longitude);
  }

  Future<void> _openShareForm() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ShareRestaurantScreen(),
      ),
    );
    if (created == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Food food = widget.food;
    final bool hasLocation = _userLat != null && _userLng != null;

    return Scaffold(
      appBar: GradientAppBar(
        title: Text('Quán phục vụ: ${food.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyState(
                  foodName: food.name,
                  onShare: _openShareForm,
                )
              : Column(
                  children: <Widget>[
                    if (!hasLocation)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppGradients.surfaceTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppGradients.primaryMid
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.info_outline,
                                color: AppGradients.primaryEnd),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa có vị trí của bạn nên chưa tính được '
                                'khoảng cách. Hãy bật GPS và cấp quyền vị trí.',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            return _SuggestionCard(
                              ranked: _items[index],
                              dateLabel: _dateFormat.format(
                                _items[index].restaurant.createdAt,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _loading || _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'suggest_share_fab',
              onPressed: _openShareForm,
              backgroundColor: AppGradients.primaryMid,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Chia sẻ quán'),
            ),
    );
  }
}

class _RankedRestaurant {
  _RankedRestaurant({
    required this.restaurant,
    required this.distanceMeters,
  });

  final SharedRestaurant restaurant;
  final double? distanceMeters;

  String get distanceLabel {
    final double? d = distanceMeters;
    if (d == null) {
      return 'Chưa rõ khoảng cách';
    }
    if (d < 1000) {
      return '${d.round()} m';
    }
    return '${(d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)} km';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.foodName, required this.onShare});

  final String foodName;
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
              Icons.storefront_rounded,
              size: 72,
              color: AppGradients.primaryOrange,
            ),
            const SizedBox(height: 16),
            GradientText(
              'Chưa có quán nào phục vụ "$foodName"',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chia sẻ một quán ngon bạn biết, có phục vụ món này để mọi người cùng thưởng thức nhé!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: onShare,
              icon: const Icon(Icons.add_location_alt_rounded),
              child: const Text('Chia sẻ quán'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.ranked,
    required this.dateLabel,
  });

  final _RankedRestaurant ranked;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final SharedRestaurant item = ranked.restaurant;
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.near_me_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      ranked.distanceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
              const Spacer(),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
