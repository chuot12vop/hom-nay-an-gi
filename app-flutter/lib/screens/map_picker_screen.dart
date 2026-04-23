import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';

/// Màn hình chọn vị trí trên bản đồ OpenStreetMap.
/// - Khi mở: tự động di chuyển camera + thả ghim tại vị trí hiện tại
///   (nếu chưa có [initialLocation] và được cấp quyền).
/// - Chạm vào bản đồ để đổi vị trí ghim.
/// - Nút "Vị trí của tôi" để đưa ghim quay lại vị trí hiện tại.
/// - Nhấn "Xác nhận" để trả về [LatLng] cho màn hình gọi.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _defaultCenter = LatLng(16.047079, 108.206230); // Đà Nẵng
  static const double _defaultZoom = 14;

  final MapController _mapController = MapController();
  LatLng? _picked;
  bool _loadingMyLocation = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation;
    if (widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToCurrentLocation(silent: true);
      });
    }
  }

  /// Lấy vị trí hiện tại, di chuyển camera và thả ghim.
  /// - [silent]: không hiển thị snack/báo lỗi (dùng cho lần tự động khi mở màn).
  Future<void> _moveToCurrentLocation({bool silent = false}) async {
    setState(() => _loadingMyLocation = true);
    try {
      final bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!silent) {
          _showSnack('Vui lòng bật dịch vụ vị trí');
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent) {
          _showSnack('Ứng dụng chưa được cấp quyền vị trí');
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) {
        return;
      }
      final LatLng here = LatLng(position.latitude, position.longitude);
      setState(() => _picked = here);
      _mapController.move(here, 16);
    } catch (_) {
      if (!silent) {
        _showSnack('Không lấy được vị trí hiện tại');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMyLocation = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirm() {
    final LatLng? p = _picked;
    if (p == null) {
      _showSnack('Vui lòng chạm bản đồ để chọn vị trí');
      return;
    }
    Navigator.of(context).pop<LatLng>(p);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _picked ?? widget.initialLocation ?? _defaultCenter;
    final LatLng? picked = _picked;

    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Chọn vị trí trên bản đồ'),
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _defaultZoom,
              minZoom: 3,
              maxZoom: 19,
              onTap: (TapPosition _, LatLng latLng) {
                setState(() => _picked = latLng);
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.homnayangi.app',
                maxNativeZoom: 19,
              ),
              if (picked != null)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: picked,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppGradients.primaryEnd,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'map_picker_my_location',
              onPressed: _loadingMyLocation
                  ? null
                  : () => _moveToCurrentLocation(),
              backgroundColor: Colors.white,
              foregroundColor: AppGradients.primaryMid,
              child: _loadingMyLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (picked != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Đã chọn: ${picked.latitude.toStringAsFixed(6)}, '
                      '${picked.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                GradientButton(
                  onPressed: picked == null ? null : _confirm,
                  icon: const Icon(Icons.check_rounded),
                  child: const Text('Xác nhận vị trí'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
