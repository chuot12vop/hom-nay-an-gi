import 'package:intl/intl.dart';

/// Định dạng số theo locale — tương đương [`Number.prototype.toLocaleString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toLocaleString) trên JS.
abstract final class CommonService {
  CommonService._();

  /// [locale] ví dụ `vi`, `vi-VN`, `en-US` (BCP 47).
  ///
  /// [decimalDigits]: cố định số chữ số thập phân; bỏ qua thì dùng mẫu decimal của locale.
  static String toLocalString(
    num value, {
    String locale = 'vi',
    int? decimalDigits,
  }) {
    if (decimalDigits != null) {
      return NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: decimalDigits,
      ).format(value);
    }
    return NumberFormat.decimalPattern(locale).format(value);
  }
}
