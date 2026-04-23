import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lấy tọa độ khi có quyền và dịch vụ bật; nếu thành công thì lưu cục bộ.
class UserLocationService {
  UserLocationService();

  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';

  /// Đọc tọa độ đã lưu (nếu có).
  Future<({double? latitude, double? longitude})> readSaved() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyLatitude) || !prefs.containsKey(_keyLongitude)) {
      return (latitude: null, longitude: null);
    }
    return (
      latitude: prefs.getDouble(_keyLatitude),
      longitude: prefs.getDouble(_keyLongitude),
    );
  }

  /// Kiểm tra quyền, lấy vị trí hiện tại và lưu lat/lng khi thành công.
  Future<void> refreshAndPersist() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatitude, position.latitude);
    await prefs.setDouble(_keyLongitude, position.longitude);
  }
}
