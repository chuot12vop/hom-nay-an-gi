class Food {
  const Food({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.mealId,
    required this.priceVnd,
    required this.ingredientIds,
    this.imageUrl,
    this.recipeUrl,
    this.youtubeUrl,
  });

  final String id;
  final String name;
  final String categoryId;
  final String mealId;
  final int priceVnd;
  final List<String> ingredientIds;

  /// Ảnh món (URL).
  final String? imageUrl;

  /// Trang công thức (http/https) — hiển thị trong WebView.
  final String? recipeUrl;

  /// URL hoặc mã video YouTube.
  final String? youtubeUrl;

  /// Trích 11 ký tự video id từ URL youtube / youtu.be hoặc chuỗi id thuần.
  static String? parseYoutubeVideoId(String? urlOrId) {
    if (urlOrId == null) {
      return null;
    }
    final String s = urlOrId.trim();
    if (s.isEmpty) {
      return null;
    }
    final RegExp idOnly = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idOnly.hasMatch(s)) {
      return s;
    }
    final Uri? uri = Uri.tryParse(s);
    if (uri == null) {
      return null;
    }
    final String host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      if (uri.pathSegments.isEmpty) {
        return null;
      }
      final String id = uri.pathSegments.first;
      return idOnly.hasMatch(id) ? id : null;
    }
    if (host.contains('youtube.com')) {
      final String? v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty && idOnly.hasMatch(v)) {
        return v;
      }
      final List<String> segs = uri.pathSegments;
      final int embed = segs.indexOf('embed');
      if (embed >= 0 && embed + 1 < segs.length) {
        final String id = segs[embed + 1];
        return idOnly.hasMatch(id) ? id : null;
      }
      final int shorts = segs.indexOf('shorts');
      if (shorts >= 0 && shorts + 1 < segs.length) {
        final String id = segs[shorts + 1];
        return idOnly.hasMatch(id) ? id : null;
      }
    }
    return null;
  }
}
