import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/food.dart';
import '../models/sheet_short_video.dart';
import '../models/sheet_data.dart';
import '../services/google_sheet_service.dart';
import '../services/youtube_oembed_service.dart';
import '../theme/app_gradients.dart';
import '../utils/youtube_video_id.dart';
import '../widgets/youtube_cover_player.dart';

/// Vuốt dọc xem short YouTube — dữ liệu từ tab sheet “videos”, cùng [YoutubePlayer] như chi tiết món.
///
/// [isActiveTab] — tab bottom bar “Video” đang được chọn; `false` thì hủy [YoutubePlayerController]
/// để không tải / phát nền khi [IndexedStack] ẩn màn này.
class ShortVideosScreen extends StatefulWidget {
  const ShortVideosScreen({required this.isActiveTab, super.key});

  final bool isActiveTab;

  @override
  State<ShortVideosScreen> createState() => _ShortVideosScreenState();
}

class _ShortVideosScreenState extends State<ShortVideosScreen> {
  final GoogleSheetService _sheetService = GoogleSheetService();
  final PageController _pageController = PageController();

  SheetData? _data;
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  YoutubePlayerController? _playerController;
  YoutubePlayerController? _preloadController1;
  YoutubePlayerController? _preloadController2;

  /// Huỷ kết quả oEmbed cũ khi đổi clip (thứ tự request).
  int _oembedRequestGen = 0;

  static const YoutubePlayerFlags _preloadFlags = YoutubePlayerFlags(
    autoPlay: false,
    mute: true,
    enableCaption: false,
    hideControls: true,
  );

  List<SheetShortVideo> get _playable {
    final SheetData? d = _data;
    if (d == null) {
      return <SheetShortVideo>[];
    }
    return d.shortVideos
        .where((SheetShortVideo v) => resolveYoutubeVideoId(v.url) != null)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ShortVideosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActiveTab && oldWidget.isActiveTab) {
      _releasePlayer();
      setState(() {});
      return;
    }
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      if (_data != null &&
          !_loading &&
          _error == null &&
          _playable.isNotEmpty) {
        _syncControllersForIndex(_currentIndex);
        setState(() {});
      }
    }
  }

  /// Hủy mọi player (chính + 2 preload) — khi rời tab Video hoặc đổi index.
  void _releasePlayer() {
    _playerController?.dispose();
    _playerController = null;
    _preloadController1?.dispose();
    _preloadController1 = null;
    _preloadController2?.dispose();
    _preloadController2 = null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SheetData data = await _sheetService.fetchAllTables();
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
        _currentIndex = 0;
      });
      if (mounted && widget.isActiveTab) {
        _syncControllersForIndex(0);
        setState(() {});
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _data = null;
        _loading = false;
        _error = 'Không tải được dữ liệu.';
      });
    }
  }

  /// Player chính + preload 2 clip phía sau (index+1, index+2) để vuốt tới mượt hơn.
  void _syncControllersForIndex(int index) {
    if (!widget.isActiveTab) {
      _releasePlayer();
      return;
    }
    _releasePlayer();
    final List<SheetShortVideo> list = _playable;
    if (index < 0 || index >= list.length) {
      return;
    }

    final String? mainId = resolveYoutubeVideoId(list[index].url);
    if (mainId != null) {
      _playerController = YoutubePlayerController(
        initialVideoId: mainId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
    }

    if (index + 1 < list.length) {
      final String? id1 = resolveYoutubeVideoId(list[index + 1].url);
      if (id1 != null) {
        _preloadController1 = YoutubePlayerController(
          initialVideoId: id1,
          flags: _preloadFlags,
        );
      }
    }
    if (index + 2 < list.length) {
      final String? id2 = resolveYoutubeVideoId(list[index + 2].url);
      if (id2 != null) {
        _preloadController2 = YoutubePlayerController(
          initialVideoId: id2,
          flags: _preloadFlags,
        );
      }
    }

    _requestOembedAspectRefresh(list[index]);
    _prefetchOembedNeighbors(list, index);
  }

  void _prefetchOembedNeighbors(List<SheetShortVideo> list, int index) {
    for (final int i in <int>[index + 1, index + 2]) {
      if (i < 0 || i >= list.length) {
        continue;
      }
      final SheetShortVideo v = list[i];
      final String? videoId = resolveYoutubeVideoId(v.url);
      if (videoId == null) {
        continue;
      }
      YoutubeOembedService.instance
          .fetchAspectRatio(videoId: videoId, pageUrl: v.url)
          .then((double? _) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  void _requestOembedAspectRefresh(SheetShortVideo v) {
    final String? videoId = resolveYoutubeVideoId(v.url);
    if (videoId == null) {
      return;
    }
    _oembedRequestGen++;
    final int gen = _oembedRequestGen;
    YoutubeOembedService.instance
        .fetchAspectRatio(videoId: videoId, pageUrl: v.url)
        .then((double? _) {
      if (!mounted || gen != _oembedRequestGen) {
        return;
      }
      setState(() {});
    });
  }

  double _playerAspectRatio(SheetShortVideo v, String? videoId) {
    if (videoId != null) {
      final double? cached =
          YoutubeOembedService.instance.cachedAspectForVideoId(videoId);
      if (cached != null) {
        return cached;
      }
    }
    return youtubeDisplayAspectRatio(v.url);
  }

  double _preloadAspect(String? videoId, String? pageUrl) {
    if (videoId != null) {
      final double? c =
          YoutubeOembedService.instance.cachedAspectForVideoId(videoId);
      if (c != null) {
        return c;
      }
    }
    return youtubeDisplayAspectRatio(pageUrl);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (widget.isActiveTab) {
        _syncControllersForIndex(index);
      }
    });
  }

  Food? _foodFor(SheetShortVideo v) {
    final String? foodId = v.foodId;
    if (foodId == null || foodId.isEmpty) {
      return null;
    }
    final List<Food> foods = _data?.foods ?? <Food>[];
    for (final Food f in foods) {
      if (f.id == foodId) {
        return f;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _releasePlayer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppGradients.primaryMid),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final List<SheetShortVideo> list = _playable;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Chưa có video short hợp lệ.\nThêm dòng trong tab “videos” (cột url là link YouTube hoặc Shorts).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8A8A8E),
                ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (BuildContext context, int index) {
              final SheetShortVideo v = list[index];
              final bool isActive = index == _currentIndex;
              final Food? food = _foodFor(v);
              final String? vid = resolveYoutubeVideoId(v.url);
              final double displayAr = _playerAspectRatio(v, vid);

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (widget.isActiveTab &&
                      isActive &&
                      _playerController != null)
                    Positioned.fill(
                      child: YoutubeCoverPlayer(
                        key: ValueKey<String>('short-$vid'),
                        controller: _playerController!,
                        videoAspectRatio: displayAr,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: AppGradients.primaryMid,
                        progressColors: ProgressBarColors(
                          playedColor: AppGradients.primaryEnd,
                          handleColor: AppGradients.primaryMid,
                          bufferedColor:
                              AppGradients.primaryStart.withValues(alpha: 0.35),
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    )
                  else
                    _ShortPlaceholderThumb(thumbnailUrl: v.thumbnailUrl),
                  Positioned(
                    left: 16,
                    right: 72,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (food != null)
                          Text(
                            food.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              shadows: <Shadow>[
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        if (v.category != null && v.category!.isNotEmpty)
                          Text(
                            v.category!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (widget.isActiveTab &&
              (_preloadController1 != null || _preloadController2 != null))
            Positioned.fill(
              child: IgnorePointer(
                child: Offstage(
                  offstage: true,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 200,
                      height: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_preloadController1 != null)
                            Builder(
                              builder: (BuildContext context) {
                                final SheetShortVideo pv =
                                    list[_currentIndex + 1];
                                final String? pid =
                                    resolveYoutubeVideoId(pv.url);
                                final double par =
                                    _preloadAspect(pid, pv.url);
                                return SizedBox(
                                  width: 160,
                                  height: 160 / par,
                                  child: YoutubePlayer(
                                    key: ValueKey<String>(
                                      'preload1-${pid ?? ''}',
                                    ),
                                    controller: _preloadController1!,
                                    width: 160,
                                    aspectRatio: par,
                                    showVideoProgressIndicator: false,
                                  ),
                                );
                              },
                            ),
                          if (_preloadController2 != null)
                            Builder(
                              builder: (BuildContext context) {
                                final SheetShortVideo pv =
                                    list[_currentIndex + 2];
                                final String? pid =
                                    resolveYoutubeVideoId(pv.url);
                                final double par =
                                    _preloadAspect(pid, pv.url);
                                return SizedBox(
                                  width: 160,
                                  height: 160 / par,
                                  child: YoutubePlayer(
                                    key: ValueKey<String>(
                                      'preload2-${pid ?? ''}',
                                    ),
                                    controller: _preloadController2!,
                                    width: 160,
                                    aspectRatio: par,
                                    showVideoProgressIndicator: false,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortPlaceholderThumb extends StatelessWidget {
  const _ShortPlaceholderThumb({this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final String? t = thumbnailUrl?.trim();
    if (t != null && t.isNotEmpty) {
      return Image.network(
        t,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                const ColoredBox(color: Colors.black),
      );
    }
    return const ColoredBox(color: Colors.black);
  }
}
