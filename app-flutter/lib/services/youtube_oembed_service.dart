import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lấy tỉ lệ khung (chiều ngang / chiều dọc) từ [oEmbed](https://oembed.com/) của YouTube — độ phân giải embed, đủ để phân biệt ngang/dọc.
class YoutubeOembedService {
  YoutubeOembedService._();
  static final YoutubeOembedService instance = YoutubeOembedService._();

  final Map<String, double> _aspectByVideoId = <String, double>{};

  double? cachedAspectForVideoId(String videoId) {
    final String k = videoId.trim();
    if (k.isEmpty) {
      return null;
    }
    return _aspectByVideoId[k];
  }

  /// [pageUrl] nên là URL gốc (watch / shorts / youtu.be) để oEmbed trả đúng kích thước embed.
  Future<double?> fetchAspectRatio({
    required String videoId,
    String? pageUrl,
  }) async {
    final String id = videoId.trim();
    if (id.isEmpty) {
      return null;
    }
    final double? cached = _aspectByVideoId[id];
    if (cached != null) {
      return cached;
    }

    String embedParam = 'https://www.youtube.com/watch?v=$id';
    final String? raw = pageUrl?.trim();
    if (raw != null && raw.isNotEmpty && raw.startsWith('http')) {
      embedParam = raw;
    }

    final Uri uri = Uri.https('www.youtube.com', '/oembed', <String, String>{
      'url': embedParam,
      'format': 'json',
    });

    try {
      final http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final num? w = decoded['width'] as num?;
      final num? h = decoded['height'] as num?;
      if (w == null || h == null || w <= 0 || h <= 0) {
        return null;
      }
      final double aspect = w.toDouble() / h.toDouble();
      if (aspect <= 0 || aspect > 10 || aspect < 0.1) {
        return null;
      }
      _aspectByVideoId[id] = aspect;
      return aspect;
    } catch (_) {
      return null;
    }
  }
}
