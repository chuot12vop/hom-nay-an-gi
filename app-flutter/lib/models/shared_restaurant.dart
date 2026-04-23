/// Quán ăn do người dùng chia sẻ cục bộ (chưa có backend).
class SharedRestaurant {
  const SharedRestaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.provinceCode,
    required this.provinceName,
    required this.wardCode,
    required this.wardName,
    required this.detailAddress,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.foodIds = const <String>[],
    this.foodNames = const <String>[],
  });

  final String id;
  final String name;
  final String description;
  final String provinceCode;
  final String provinceName;
  final String wardCode;
  final String wardName;
  final String detailAddress;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  /// Danh sách món ăn quán có (id tham chiếu Google Sheet).
  final List<String> foodIds;

  /// Tên món — lưu kèm để hiển thị offline, không cần tải lại sheet.
  final List<String> foodNames;

  String get fullAddress {
    final List<String> parts = <String>[
      if (detailAddress.trim().isNotEmpty) detailAddress.trim(),
      if (wardName.isNotEmpty) wardName,
      if (provinceName.isNotEmpty) provinceName,
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'provinceCode': provinceCode,
        'provinceName': provinceName,
        'wardCode': wardCode,
        'wardName': wardName,
        'detailAddress': detailAddress,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'foodIds': foodIds,
        'foodNames': foodNames,
      };

  static SharedRestaurant fromJson(Map<String, dynamic> json) {
    return SharedRestaurant(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      provinceCode: json['provinceCode'] as String? ?? '',
      provinceName: json['provinceName'] as String? ?? '',
      wardCode: json['wardCode'] as String? ?? '',
      wardName: json['wardName'] as String? ?? '',
      detailAddress: json['detailAddress'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      foodIds: _parseStringList(json['foodIds']),
      foodNames: _parseStringList(json['foodNames']),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((dynamic e) => e.toString()).toList();
    }
    return const <String>[];
  }
}
