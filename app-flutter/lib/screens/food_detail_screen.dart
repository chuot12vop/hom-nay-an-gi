import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/food.dart';
import '../services/common_service.dart';
import '../theme/app_gradients.dart';
import '../services/youtube_oembed_service.dart';
import '../utils/youtube_video_id.dart';
import '../widgets/gradient_widgets.dart';
import '../widgets/youtube_cover_player.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({required this.food, super.key});

  final Food food;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      _youtubeController?.dispose();
      _youtubeController = null;
    } else {
      _ensureYoutubeController();
    }
    setState(() {});
  }

  void _ensureYoutubeController() {
    if (_youtubeController != null) {
      return;
    }
    final String? videoId = resolveYoutubeVideoId(widget.food.youtubeUrl);
    if (videoId == null) {
      return;
    }
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Food food = widget.food;

    return Scaffold(
      appBar: AppBar(
        title: GradientText(food.name),
        backgroundColor: Colors.white,
        foregroundColor: AppGradients.primaryMid,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppGradients.primaryEnd,
          unselectedLabelColor: const Color(0xFF8A8A8E),
          indicatorColor: AppGradients.primaryMid,
          tabs: const <Widget>[
            Tab(text: 'Công thức nấu'),
            Tab(text: 'Video hướng dẫn'),
          ],
        ),
      ),
      body: _tabController.index == 0
          ? _RecipeTab(food: food)
          : SizedBox.expand(
              child: _VideoTab(
                controller: _youtubeController,
                youtubeUrl: food.youtubeUrl,
              ),
            ),
    );
  }
}

bool _isHttpRecipeUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return false;
  }
  final Uri? uri = Uri.tryParse(url.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class _RecipeTab extends StatefulWidget {
  const _RecipeTab({required this.food});

  final Food food;

  @override
  State<_RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends State<_RecipeTab> {
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    final String? raw = widget.food.recipeUrl;
    if (_isHttpRecipeUrl(raw)) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(raw!.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Food food = widget.food;
    final bool hasWebRecipe = _webController != null;
    final double screenH = MediaQuery.sizeOf(context).height;
    // WebView cần chiều cao hữu hạn; toàn bộ Column cuộn trong SingleChildScrollView.
    final double webHeight = (screenH * 0.58).clamp(380.0, 820.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GradientText(
              food.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Thiệt hại trên đầu người: ${CommonService.toLocalString(food.priceVnd)} VND',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _FoodImage(url: food.imageUrl),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (hasWebRecipe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: webHeight,
                  child: WebViewWidget(controller: _webController!),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Text(
                'Công thức chưa được cập nhật',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF8A8A8E),
                    ),
              ),
            ),
          if (hasWebRecipe) const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return ColoredBox(
        color: const Color(0xFFF0E8E2),
        child: Icon(
          Icons.restaurant_rounded,
          size: 72,
          color: AppGradients.primaryMid.withValues(alpha: 0.45),
        ),
      );
    }
    final Uri? uri = Uri.tryParse(url!.trim());
    if (uri == null || !uri.hasScheme) {
      return ColoredBox(
        color: const Color(0xFFF0E8E2),
        child: Icon(
          Icons.broken_image_outlined,
          size: 56,
          color: AppGradients.primaryMid.withValues(alpha: 0.45),
        ),
      );
    }
    return Image.network(
      url!.trim(),
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return ColoredBox(
          color: const Color(0xFFF0E8E2),
          child: Icon(
            Icons.broken_image_outlined,
            size: 56,
            color: AppGradients.primaryMid.withValues(alpha: 0.45),
          ),
        );
      },
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            color: AppGradients.primaryMid,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}

class _VideoTab extends StatefulWidget {
  const _VideoTab({
    required this.controller,
    required this.youtubeUrl,
  });

  final YoutubePlayerController? controller;
  final String? youtubeUrl;

  @override
  State<_VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<_VideoTab> {
  int _oembedGen = 0;

  @override
  void initState() {
    super.initState();
    _scheduleOembedAspect();
  }

  @override
  void didUpdateWidget(covariant _VideoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeUrl != widget.youtubeUrl ||
        oldWidget.controller != widget.controller) {
      _scheduleOembedAspect();
    }
  }

  void _scheduleOembedAspect() {
    final String? videoId = resolveYoutubeVideoId(widget.youtubeUrl);
    if (videoId == null) {
      return;
    }
    _oembedGen++;
    final int gen = _oembedGen;
    YoutubeOembedService.instance
        .fetchAspectRatio(videoId: videoId, pageUrl: widget.youtubeUrl)
        .then((double? _) {
      if (!mounted || gen != _oembedGen) {
        return;
      }
      setState(() {});
    });
  }

  double get _aspectRatio {
    final String? videoId = resolveYoutubeVideoId(widget.youtubeUrl);
    if (videoId != null) {
      final double? c =
          YoutubeOembedService.instance.cachedAspectForVideoId(videoId);
      if (c != null) {
        return c;
      }
    }
    return youtubeDisplayAspectRatio(widget.youtubeUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Video hướng dẫn chưa được cập nhật',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8A8A8E),
                ),
          ),
        ),
      );
    }

    return YoutubeCoverPlayer(
      controller: widget.controller!,
      videoAspectRatio: _aspectRatio,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppGradients.primaryMid,
      progressColors: ProgressBarColors(
        playedColor: AppGradients.primaryEnd,
        handleColor: AppGradients.primaryMid,
        bufferedColor: AppGradients.primaryStart.withValues(alpha: 0.35),
        backgroundColor: Colors.black26,
      ),
    );
  }
}
