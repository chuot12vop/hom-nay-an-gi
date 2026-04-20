import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../theme/app_gradients.dart';

/// Phủ kín khung cho [constraints] (BoxFit.cover), giữ đúng [videoAspectRatio] (chiều ngang / chiều dọc).
class YoutubeCoverPlayer extends StatelessWidget {
  const YoutubeCoverPlayer({
    required this.controller,
    required this.videoAspectRatio,
    this.showVideoProgressIndicator = true,
    this.progressIndicatorColor,
    this.progressColors,
    super.key,
  });

  final YoutubePlayerController controller;
  final double videoAspectRatio;
  final bool showVideoProgressIndicator;
  final Color? progressIndicatorColor;
  final ProgressBarColors? progressColors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double mw = constraints.maxWidth;
        final double mh = constraints.maxHeight;
        if (mw <= 0 || mh <= 0) {
          return const SizedBox.shrink();
        }
        final Color indicatorColor =
            progressIndicatorColor ?? AppGradients.primaryMid;
        final ProgressBarColors colors = progressColors ??
            ProgressBarColors(
              playedColor: AppGradients.primaryEnd,
              handleColor: AppGradients.primaryMid,
              bufferedColor:
                  AppGradients.primaryStart.withValues(alpha: 0.35),
              backgroundColor: Colors.black26,
            );
        return ClipRect(
          child: ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: mw,
              height: mh,
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: mw,
                  height: mw / videoAspectRatio,
                  child: YoutubePlayer(
                    controller: controller,
                    width: mw,
                    aspectRatio: videoAspectRatio,
                    showVideoProgressIndicator: showVideoProgressIndicator,
                    progressIndicatorColor: indicatorColor,
                    progressColors: colors,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
