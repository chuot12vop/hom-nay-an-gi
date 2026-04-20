import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/food.dart';

/// Trích id YouTube từ URL / id thuần — dùng chung cho chi tiết món và màn short.
String? resolveYoutubeVideoId(String? urlOrId) {
  if (urlOrId == null) {
    return null;
  }
  final String s = urlOrId.trim();
  if (s.isEmpty) {
    return null;
  }
  String? id = YoutubePlayer.convertUrlToId(s);
  if (id != null) {
    return id;
  }
  String normalized = s;
  if (normalized.startsWith('http://')) {
    normalized = 'https://${normalized.substring(7)}';
  } else if (!normalized.contains('://') &&
      (normalized.contains('youtube.com') || normalized.contains('youtu.be'))) {
    normalized = 'https://$normalized';
  }
  id = YoutubePlayer.convertUrlToId(normalized);
  return id ?? Food.parseYoutubeVideoId(normalized);
}

/// Tỉ lệ khung hiển thị (chiều ngang / chiều dọc) — Shorts dọc 9:16, video thường 16:9.
double youtubeDisplayAspectRatio(String? url) {
  if (url == null || url.trim().isEmpty) {
    return 16 / 9;
  }
  final String u = url.toLowerCase();
  if (u.contains('/shorts/')) {
    return 9 / 16;
  }
  return 16 / 9;
}
