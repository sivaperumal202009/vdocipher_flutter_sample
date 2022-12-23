import 'package:flutter/material.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';
import 'package:vdocipher_flutter_sample/vdo_player_service.dart';

class CustomVdoPlayerView extends StatefulWidget {
  final VdoPlayerService service;

  const CustomVdoPlayerView({super.key, required this.service});

  @override
  State<CustomVdoPlayerView> createState() => _CustomVdoPlayerViewState();
}

class _CustomVdoPlayerViewState extends State<CustomVdoPlayerView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.service.isFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        return Flexible(
          flex: 0,
          child: SizedBox(
            height: widget.service.getHeightOfPlayerView(context),
            width: widget.service.getWidthOfPlayerView(context),
            child: Stack(
              children: [
                VdoPlayer(
                  embedInfo: widget.service.embedInfo,
                  onPlayerCreated: (controller) =>
                      widget.service.onPlayerCreated(controller),
                  controls: false,
                  onError: (_) {},
                ),
                ValueListenableBuilder<VdoError?>(
                  valueListenable: widget.service.vdoErrorNotifier,
                  builder: (context, vdoError, _) {
                    if (vdoError != null) {
                      return _VdoErrorData(service: widget.service);
                    }
                    return ValueListenableBuilder<bool>(
                      valueListenable: widget.service.showControlsNotifier,
                      builder: (context, showControls, _) {
                        if (!showControls) {
                          return GestureDetector(
                            onTap: widget.service.toggleShowControls,
                            child: Container(
                              color: Colors.transparent,
                              height:
                                  widget.service.getHeightOfPlayerView(context),
                              width:
                                  widget.service.getWidthOfPlayerView(context),
                            ),
                          );
                        }
                        return _VdoControlsBar(
                          service: widget.service,
                          isFullScreen: isFullScreen,
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.service.isLoadingNotifier,
                  builder: (context, isLoading, _) {
                    if (isLoading) {
                      return const Center(
                        child: SizedBox(
                          height: 45,
                          width: 45,
                          child: CustomProgressIndicator(height: 45),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.service.dispose();
    super.dispose();
  }
}

class _VdoControlsBar extends StatelessWidget {
  final VdoPlayerService service;
  final bool isFullScreen;

  const _VdoControlsBar({
    required this.service,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: service.getHeightOfPlayerView(context),
        width: service.getWidthOfPlayerView(context),
        child: GestureDetector(
          onTap: service.toggleShowControls,
          child: ColoredBox(
            color: Colors.black.withOpacity(0.35),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: isFullScreen
                              ? CustomText(
                                  service.value.mediaInfo?.title ?? "",
                                  color: service.primaryColor,
                                  maxLines: 1,
                                  showEllipsis: true,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 5),
                        if (service.hasSubtitles)
                          _CustomControlIcon(
                            iconsData: Icons.closed_caption_sharp,
                            onPressed: () => _onSubtitlePressed(context),
                            iconColor: service.primaryColor,
                          ),
                        if (service.hasSpeed)
                          _CustomControlIcon(
                            iconsData: Icons.speed,
                            onPressed: () => _onSpeedPressed(context),
                            iconColor: service.primaryColor,
                          ),
                        if (service.hasVideoQuality)
                          _CustomControlIcon(
                            iconsData: Icons.hd,
                            onPressed: () => _onVideoQualityPressed(context),
                            iconColor: service.primaryColor,
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: service.isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      if (isLoading) return const SizedBox.shrink();
                      return ValueListenableBuilder<bool>(
                        valueListenable: service.isEndedNotifier,
                        builder: (context, isEnded, _) {
                          if (isEnded) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CustomControlIcon(
                                  iconsData: Icons.replay_outlined,
                                  onPressed: service.reload,
                                  iconColor: service.primaryColor,
                                  size: 50,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CustomControlIcon(
                                iconsData: Icons.replay_10,
                                onPressed: service.rewind,
                                iconColor: service.primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 30),
                              ValueListenableBuilder<bool>(
                                valueListenable: service.isPlayingNotifier,
                                builder: (context, isPlaying, _) {
                                  return _CustomControlIcon(
                                    iconsData: isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    onPressed: service.playPause,
                                    padding: EdgeInsets.zero,
                                    iconColor: service.primaryColor,
                                    size: 50,
                                  );
                                },
                              ),
                              const SizedBox(width: 30),
                              _CustomControlIcon(
                                iconsData: Icons.forward_10,
                                onPressed: service.forward,
                                size: 28,
                                iconColor: service.primaryColor,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const SizedBox(width: 14),
                      ValueListenableBuilder<String>(
                        valueListenable: service.currentDurationStringNotifier,
                        builder: (context, durationString, _) {
                          if (durationString.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return CustomText(
                            "$durationString / ${service.totalDuration}",
                            color: service.primaryColor,
                            fontSize: 12,
                            height: null,
                          );
                        },
                      ),
                      const Spacer(),
                      _CustomControlIcon(
                        iconsData: isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        onPressed: service.toggleFullScreen,
                        iconColor: service.primaryColor,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(1),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: service.currentPostionNotifier,
                    builder: (context, currentValue, _) {
                      return Container(
                        height: 35,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SliderTheme(
                            data: SliderThemeData(
                              thumbColor: service.secondaryColor,
                              trackHeight: 0.8,
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: currentValue,
                              max: service.value.duration.inSeconds.toDouble(),
                              onChangeStart: (_) => service.toggleSeeking(true),
                              onChangeEnd: (_) => service.toggleSeeking(false),
                              onChanged: service.changePosition,
                              inactiveColor: service.onSecondaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isFullScreen ? 8 : 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onVideoQualityPressed(BuildContext context) {
    _showBottomSheet(
      context,
      _CustomSheet<VideoTrack>(
        title: VdoStringConstants.selectVideoQuality,
        items: service.videoTracks,
        displayTextTransformer: service.getVideoQualityDisplayText,
        isSelectedTransformer: service.isVideoQualitySelected,
        onTap: service.setVideoTrack,
      ),
    );
  }

  void _onSpeedPressed(BuildContext context) {
    _showBottomSheet(
      context,
      _CustomSheet<double>(
        title: VdoStringConstants.selectPlaybackSpeed,
        items: service.playbackSpeedList,
        displayTextTransformer: service.getSpeedDisplayText,
        isSelectedTransformer: service.isSpeedSelected,
        onTap: service.setSpeed,
      ),
    );
  }

  void _onSubtitlePressed(BuildContext context) {
    _showBottomSheet(
      context,
      _CustomSheet<SubtitleTrack>(
        title: VdoStringConstants.selectSubtitles,
        items: service.subtitleTracks,
        displayTextTransformer: service.getSubtitleDisplayText,
        isSelectedTransformer: service.isSubtitleSelected,
        onTap: service.setSubtitleTrack,
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Widget widget) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => widget,
    );
  }
}

class _VdoErrorData extends StatelessWidget {
  const _VdoErrorData({required this.service});

  final VdoPlayerService service;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: service.reload,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              color: service.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CustomText(
                service.errorMessage,
                color: service.primaryColor,
                textAlign: TextAlign.center,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.replay_outlined,
                  color: service.primaryColor,
                ),
                const SizedBox(width: 10),
                CustomText(
                  VdoStringConstants.tapToRetry,
                  color: service.primaryColor,
                  height: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomControlIcon extends StatelessWidget {
  final IconData iconsData;
  final Function() onPressed;
  final EdgeInsets padding;
  final double size;
  final Color iconColor;
  final BoxConstraints? constraints;

  const _CustomControlIcon({
    required this.iconsData,
    required this.onPressed,
    this.padding = const EdgeInsets.all(8),
    this.size = 24,
    this.iconColor = Colors.white,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: padding,
      constraints: constraints,
      icon: Icon(
        iconsData,
        color: iconColor,
        size: size,
      ),
    );
  }
}

class _CustomSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String? Function(T) displayTextTransformer;
  final bool Function(T) isSelectedTransformer;
  final Function(T) onTap;

  const _CustomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.displayTextTransformer,
    required this.isSelectedTransformer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        maxHeight: 375,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          CustomText(
            title,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final T item = items[index];
                return InkWell(
                  onTap: () {
                    onTap(item);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: isSelectedTransformer(item)
                              ? const Icon(Icons.check, size: 20)
                              : null,
                        ),
                        CustomText(displayTextTransformer(item)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomText extends StatelessWidget {
  final String? text;
  final double? fontSize;
  final Color? color;
  final TextAlign? textAlign;
  final GestureTapCallback? onTap;
  final bool? isUnderLine;
  final bool? isStrikeThrough;
  final bool? showEllipsis;
  final int? maxLines;
  final double? height;
  final double? decorationThickness;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final bool isSingleLine;
  final TextOverflow? textOverflow;
  final TextDecorationStyle? decorationStyle;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.color = Colors.black,
    this.textAlign = TextAlign.left,
    this.isUnderLine = false,
    this.showEllipsis = false,
    this.isStrikeThrough = false,
    this.isSingleLine = false,
    this.maxLines,
    this.fontWeight = FontWeight.normal,
    this.height = 1,
    this.decorationThickness = 2,
    this.fontStyle = FontStyle.normal,
    this.onTap,
    this.textOverflow,
    this.decorationStyle,
  });

  @override
  Widget build(BuildContext context) {
    TextDecoration deco = TextDecoration.none;
    if (isUnderLine!) {
      deco = TextDecoration.underline;
    }
    if (isStrikeThrough!) {
      deco = TextDecoration.lineThrough;
    }
    final Text textWidget = Text(
      text!,
      textAlign: textAlign,
      overflow: showEllipsis! ? TextOverflow.ellipsis : textOverflow,
      maxLines: maxLines,
      softWrap: true,
      style: TextStyle(
        height: height,
        decoration: deco,
        color: color,
        decorationThickness: decorationThickness,
        decorationStyle: decorationStyle,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        overflow: isSingleLine ? TextOverflow.ellipsis : textOverflow,
        fontSize: fontSize,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    } else {
      return textWidget;
    }
  }
}

class CustomProgressIndicator extends StatefulWidget {
  final Color bgColor;
  final Color? loaderColor;
  final bool isAbsorbing;
  final double? height;

  const CustomProgressIndicator({
    super.key,
    this.bgColor = Colors.transparent,
    this.loaderColor,
    this.isAbsorbing = false,
    this.height,
  });

  @override
  _CustomProgressIndicatorState createState() =>
      _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: widget.isAbsorbing,
      child: Container(
        height: widget.height ?? MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: widget.bgColor,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.loaderColor ?? const Color(0xff03416C),
            ),
          ),
        ),
      ),
    );
  }
}
