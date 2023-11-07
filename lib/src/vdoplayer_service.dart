import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vdocipher_flutter/vdocipher_flutter.dart';
import 'package:vdocipher_flutter_v3/helpers/color_resource.dart';
import 'package:vdocipher_flutter_v3/helpers/enums.dart';
import 'package:vdocipher_flutter_v3/helpers/font.dart';
import 'package:vdocipher_flutter_v3/helpers/string_constants.dart';
import 'package:vdocipher_flutter_v3/helpers/time_utils.dart';
import 'package:vdocipher_flutter_v3/models/video_chapter/video_chapter.dart';
import 'package:vdocipher_flutter_v3/network/video_repository.dart';
import 'package:vdocipher_flutter_v3/network/video_response/video_detail_response.dart';

class VdoPlayerService {
  // Service arguments

  /// This videoId is used to set the videoChapters for the video.
  final String vdoId;
  final EmbedInfo embedInfo;
  final Color primaryColor;
  final Color? secondaryColor;
  final Color? onPrimaryColor;
  final Color? onSecondaryColor;
  final Color loaderColor;
  final String font;
  final ValueNotifier<String?> _selectedSearchLang = ValueNotifier(null);

  /// Returns the VideoChapters once the API is completed.
  final Function(List<VideoChapter>)? onVideoChaptersLoaded;

  late VdoPlayerController _controller;

  List<double> _playbackSpeedList = [];
  List<SubtitleTrack> _subtitleTracksList = [];
  List<VideoTrack> _videoTracksList = [];
  List<VideoChapter> _videoChapters = [];

  late VideoDetailResponse _videoDetailResponse;

  Orientation? currentOrientation;

  final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);
  final ValueNotifier<bool> _showControls = ValueNotifier(false);
  final ValueNotifier<String> _currentDurationString = ValueNotifier("");
  final ValueNotifier<double> _currentPosition = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<VdoError?> _vdoError = ValueNotifier(null);
  final ValueNotifier<bool> _isEnded = ValueNotifier(false);

  Timer? _showControlsTimer;

  bool isSeeking = false;

  final void Function(VideoSessionEventEnum, [num videoTime]) onEvent;

  VdoPlayerService(
    this.embedInfo,
    this.vdoId, {
    this.secondaryColor,
    this.onPrimaryColor,
    this.primaryColor = Colors.white,
    this.onSecondaryColor = Colors.white38,
    this.loaderColor = ColorResource.color28B7E5,
    this.font = Font.nunitoSans,
    this.onVideoChaptersLoaded,
    required this.onEvent,
  });

  /// Sets the controller, initializes the video to play and
  Future<void> onPlayerCreated(VdoPlayerController controller) async {
    _controller = controller;
    _initShowControls();
    _setVideoChapters();
    onEvent(VideoSessionEventEnum.load, currentPostionNotifier.value);
    // By default first subtitle is selected in iOS, but subtitle won't be shown on video.
    // To fix this null is set to the subtitle
    if (!kIsWeb && Platform.isIOS) setSubtitleTrack(null);
    _controller.addListener(_vdoChangeListener);
  }

  void _setVideoChapters() {
    if (vdoId.isEmpty) return;

    VideoRepository.getVideoDetail(vdoId).then((resp) {
      _videoDetailResponse = resp;
      _videoChapters = resp.chapters ?? [];
      if (resp.captions != null && resp.captions!.isNotEmpty) {
        for (final caption in resp.captions!) {
          _setSubTitleTracks(caption);
        }
      }
      onVideoChaptersLoaded?.call(_videoChapters);
    });
  }

  void _setSubTitleTracks(Captions captions) {
    VideoRepository.getSRT(captions.url!).then((response) {
      captions.subtitles.addAll(response);
      captions.searchSubTitle.value.addAll(response);
    });
  }

  void onCaptionSearch(String text, Captions captions) {
    final List<SubTitlesData> data = [];
    if (text.isNotEmpty) {
      for (final item in captions.subtitles) {
        if (item.text.toLowerCase().contains(text)) {
          data.add(item);
        }
      }
    } else {
      data.addAll(captions.subtitles);
    }
    captions.searchSubTitle.value = data;
  }

  void onOrientationChange(Orientation orientation) {
    currentOrientation = orientation;
    if (currentOrientation != orientation) {
      if (orientation == Orientation.portrait && isFullScreen) {
        _isFullScreen.value = false;
        _changeOrientation();
      } else if (orientation == Orientation.landscape && !isFullScreen) {
        _isFullScreen.value = true;
        _changeOrientation();
      }
    } else {
      if (orientation == Orientation.portrait) {
        _isFullScreen.value = false;
      } else {
        _isFullScreen.value = true;
      }
    }
  }

  /// Listens and updates the variables as and when changed
  void _vdoChangeListener() {
    _isLoading.value = value.isBuffering || value.isLoading;

    // Will not update values when loading or seeking
    if (isSeeking || _isLoading.value) return;

    if (playbackSpeedList.isEmpty && value.playbackSpeedOptions.isNotEmpty) {
      _playbackSpeedList = value.playbackSpeedOptions;
    }
    if (_subtitleTracksList.isEmpty && value.subtitleTracks.isNotEmpty) {
      _subtitleTracksList = value.subtitleTracks;
    }
    if (videoTracks.isEmpty && value.videoTracks.isNotEmpty) {
      _videoTracksList = value.videoTracks;
    }
    _currentPosition.value = value.position.inSeconds.toDouble();
    _currentDurationString.value = TimeUtils.convertSecondsToDuration(
      _currentPosition.value.toString(),
    );
    _isPlaying.value = value.isPlaying;
    _vdoError.value = value.vdoError;
    _isEnded.value = value.isEnded;
    if (value.isEnded) {
      _showControls.value = true;
      onEvent(VideoSessionEventEnum.ended, _currentPosition.value);
    }
  }

  /// Toggles to full screen or portrait.
  void toggleFullScreen({
    bool shouldChangeOrientation = true,
  }) async {
    _isFullScreen.value = !isFullScreen;

    if (kIsWeb) {
      if (!_isFullScreen.value) {
        html.document.exitFullscreen();
      } else {
        await html.document.documentElement?.requestFullscreen();
      }
    } else {
      _changeOrientation();
    }
  }

  /// Denies back(pop) when in landscape, instead changes to portrait.
  Future<bool> handleBackNavigation() {
    if (isFullScreen) {
      toggleFullScreen();
      return Future.value(false);
    }
    return Future.value(true);
  }

  /// Disposes the current video controller and its data.
  void dispose() {
    _setDefaultOrientation();
    controller.pause();
    controller.dispose();
  }

  /// Toggles play or pause.
  void playPause() {
    if (_isPlaying.value) {
      controller.pause();
      onEvent(VideoSessionEventEnum.pause, _currentPosition.value);
    } else {
      controller.play();
      onEvent(VideoSessionEventEnum.play, _currentPosition.value);
    }
  }

  /// Forwards 10 seconds of the video.
  void forward() {
    final Duration seekValue = value.position + const Duration(seconds: 10);
    controller.seek(seekValue);
    onEvent(VideoSessionEventEnum.seeking, seekValue.inSeconds);
  }

  /// Rewinds 10 seconds of the video.
  void rewind() {
    final Duration seekValue = value.position - const Duration(seconds: 10);
    controller.seek(seekValue);
    onEvent(VideoSessionEventEnum.seeking, seekValue.inSeconds);
  }

  /// Initializes to show controls when the video begins.
  void _initShowControls() {
    _showControls.value = true;
    _showControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!_isEnded.value) _showControls.value = false;
    });
  }

  /// Toggles whether to show controls or not.
  void toggleShowControls() {
    if (_isEnded.value) return;
    _showControls.value = !showControls;
    _showControlsTimer?.cancel();
    if (!showControls) {
      _showControls.value = false;
    } else {
      _showControls.value = true;
      _showControlsTimer = Timer(const Duration(seconds: 3), () {
        if (!_isEnded.value) _showControls.value = false;
      });
    }
  }

  void onHoverShowControls(bool isEnable, bool isFullScreen) {
    if (_isEnded.value) return;
    _showControls.value = isEnable;
    _showControlsTimer?.cancel();
    if (isEnable && isFullScreen) {
      _showControls.value = isEnable;
      _showControlsTimer = Timer(const Duration(seconds: 3), () {
        if (!_isEnded.value) _showControls.value = false;
      });
    }
  }

  /// Change the current video position.
  void changePosition(double position) {
    controller.seek(Duration(seconds: position.toInt()));
    _currentPosition.value = position;
    onEvent(VideoSessionEventEnum.seeking, position);
  }

  /// Toggles isSeeking.
  void toggleSeeking(bool isSeekingValue) {
    isSeeking = isSeekingValue;
    _showControlsTimer?.cancel();
    _showControls.value = true;
    if (!isSeeking) {
      _showControls.value = false;
      toggleShowControls();
    }
  }

  ///Set SearchLang
  void setSearchLang(String? lang) {
    _selectedSearchLang.value = lang;
  }

  /// Reloads the video
  void reload() {
    controller.load(embedInfo);
    _currentPosition.value = 0;
    _initShowControls();
  }

  /// Changes the speed of the video
  void setSpeed(double speed) => controller.setPlaybackSpeed(speed);

  /// Sets the video quality, works only in Android.
  void setVideoTrack(VideoTrack videoTrack) =>
      controller.setVideoTrack(videoTrack);

  /// Sets subtitle track for the video
  void setSubtitleTrack(SubtitleTrack? subtitleTrack) =>
      controller.setSubtitleLanguage(subtitleTrack?.language);

  /// Changes orientation based on full screen.
  void _changeOrientation() {
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  /// Sets Default orientation, Should be used to reset to orientation constrains.
  void _setDefaultOrientation() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Returns the video quality as High, Medium or Low from the given bitrate.
  String _getVideoQuality(int bitrate) {
    final double bitrateValue = bitrate / 1024;
    if (bitrateValue > 1000) return "High";
    if (bitrateValue >= 600 && bitrate <= 1000) {
      return "Medium";
    } else {
      return "Low";
    }
  }

  /// Return the expenditure per hour.
  String _dataExpenditurePerHour(int bitsPerSec) {
    final double bytesPerHour = bitsPerSec <= 0 ? 0 : bitsPerSec * (3600 / 8);
    if (bytesPerHour == 0) return "-";

    final double megabytesPerHour = bytesPerHour / (1024 * 1024).toDouble();
    if (megabytesPerHour < 1) return "1 MB per hour";
    if (megabytesPerHour < 1000) {
      return "${megabytesPerHour.round()} MB per hour";
    }
    return "${(megabytesPerHour / 1024).round()} GB per hour";
  }

  /// Returns the video quality string.
  String qualityValue(int bitrate) {
    return "${_getVideoQuality(bitrate)} (${_dataExpenditurePerHour(bitrate)})";
  }

  /// Returns subtitle display text.
  String getSubtitleDisplayText(SubtitleTrack track) =>
      track.language ?? StringConstants.disableSubtitles;

  /// Returns whether the given subtitle is selected or not.
  bool isSubtitleSelected(SubtitleTrack track) {
    if (track.language == null) {
      return value.subtitleTrack == null;
    }
    return value.subtitleTrack == track;
  }

  /// Returns the display string for speed.
  String getSpeedDisplayText(double speedValue) {
    if (speedValue == 1.0) return StringConstants.normal;
    return "${speedValue}x";
  }

  /// Returns whether the given speed is selected or not.
  bool isSpeedSelected(double speedValue) => speedValue == value.playbackSpeed;

  /// Returns the display string of the video quality.
  String getVideoQualityDisplayText(VideoTrack track) =>
      qualityValue(track.bitrate ?? 0);

  /// Returns whether the given video quality is selected or not.
  bool isVideoQualitySelected(VideoTrack track) => track == value.videoTrack;

  /// Returns the width of the player view to render based on the portrait and landscape mode.
  double getWidthOfPlayerView(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return size.width;
  }

  /// Returns the height of the player view based on the portrait and landscape mode.
  double getHeightOfPlayerView(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    if (!isFullScreen) {
      return mediaQuery.size.width / (16 / 9);
    }
    return mediaQuery.size.height;
  }

  /// Returns the error message based on the VdoError code.
  String get errorMessage {
    final VdoError? vdoError = _vdoError.value;
    if (vdoError == null) return "";
    final String messagePrefix = "${StringConstants.error}: ${vdoError.code} -";
    switch (vdoError.code) {
      case 2013:
      case 2018:
        return "$messagePrefix ${StringConstants.otpExpiredError}";
      case 4101:
        return "$messagePrefix ${StringConstants.invalidVideoParamentersError}";
      case 4102:
        return "$messagePrefix ${StringConstants.offlineVideoNotFoundError}";
      case 5110:
      case 5124:
      case 5130:
        return "$messagePrefix ${StringConstants.checkYourInternetError}";
      case 5113:
      case 5123:
      case 5133:
      case 5152:
        return "$messagePrefix ${StringConstants.temporaryServiceError}";
      case 5151:
        return "$messagePrefix ${StringConstants.networkError}";
      case 5160:
      case 5161:
        return "$messagePrefix ${StringConstants.downloadedFiledDeletedError}";
      case 6101:
      case 6120:
      case 6122:
        return "$messagePrefix ${StringConstants.decodingError}";
      case 6102:
        return "$messagePrefix ${StringConstants.offlineVideoFailedError} ";
      case 1220:
      case 1250:
      case 1253:
      case 2021:
      case 2022:
      case 6155:
      case 6156:
      case 6157:
      case 6161:
      case 6166:
      case 6172:
      case 6177:
      case 6178:
      case 6181:
      case 6186:
      case 6190:
      case 6196:
        return "$messagePrefix ${StringConstants.phoneNotCompatibleError} ";
      case 6187:
        return "$messagePrefix ${StringConstants.rentalLicenseExpiredError}";
      default:
        return "${StringConstants.anErrorOccured}: ${vdoError.code} ${StringConstants.tapToRetry}";
    }
  }

  /// Returns the current [VdoPlayerController].
  VdoPlayerController get controller => _controller;

  /// Returns the current [VdoPlayerValue]
  VdoPlayerValue get value => _controller.value;

  bool get isFullScreen => _isFullScreen.value;
  bool get showControls => _showControls.value;
  String get currentDuration => _currentDurationString.value;

  /// Converts video player position string to Proper Date String format.
  String get totalDuration =>
      TimeUtils.convertSecondsToDuration(value.duration.inSeconds.toString());

  List<double> get playbackSpeedList => _playbackSpeedList;
  List<VideoTrack> get videoTracks => _videoTracksList;
  List<VideoChapter> get videoChapters => _videoChapters;
  VideoDetailResponse get videoDetailResponse => _videoDetailResponse;
  List<SubtitleTrack> get subtitleTracks {
    final List<SubtitleTrack> tracks = List.from(_subtitleTracksList);
    if (tracks.isEmpty) return [];
    tracks.insert(0, const SubtitleTrack(id: -1));
    return tracks;
  }

  ValueNotifier<String?> get selectedSearchLang => _selectedSearchLang;

  VideoChapter? get currentVideoChapter {
    VideoChapter? currentChapter = videoChapters.firstOrNull;

    for (int i = 0; i < videoChapters.length; i++) {
      int? endTime;
      if (i < videoChapters.length - 1) {
        endTime = videoChapters[i + 1].startTime;
      }

      if (videoChapters[i].startTime <= _currentPosition.value) {
        if (endTime == null || endTime > _currentPosition.value) {
          return videoChapters[i];
        }
      }
    }

    return currentChapter;
  }

  bool get hasSpeed => playbackSpeedList.length > 1;
  bool get hasVideoQuality => videoTracks.length > 1;
  bool get hasSubtitles => subtitleTracks.isNotEmpty;
  bool get hasVideoChapters => videoChapters.isNotEmpty;

  /// ****** Getters for notifier  ******/

  ValueNotifier<bool> get isFullScreenNotifier => _isFullScreen;
  ValueNotifier<bool> get showControlsNotifier => _showControls;
  ValueNotifier<String> get currentDurationStringNotifier =>
      _currentDurationString;
  ValueNotifier<double> get currentPostionNotifier => _currentPosition;
  ValueNotifier<bool> get isPlayingNotifier => _isPlaying;
  ValueNotifier<bool> get isLoadingNotifier => _isLoading;
  ValueNotifier<VdoError?> get vdoErrorNotifier => _vdoError;
  ValueNotifier<bool> get isEndedNotifier => _isEnded;
}
