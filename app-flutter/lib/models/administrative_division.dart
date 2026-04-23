/// Dữ liệu địa chính theo định dạng 34 tỉnh/thành (sau sáp nhập 2025):
/// mỗi tỉnh chứa trực tiếp danh sách phường/xã (không còn cấp quận/huyện).
class Province {
  const Province({
    required this.code,
    required this.name,
    required this.wards,
  });

  final String code;
  final String name;
  final List<Ward> wards;
}

class Ward {
  const Ward({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}
