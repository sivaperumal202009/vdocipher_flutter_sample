import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';

class VdoPlayerService {
  // Service arguments
  final EmbedInfo embedInfo;
  final Color primaryColor;
  final Color? secondaryColor;
  final Color? onPrimaryColor;
  final Color? onSecondaryColor;

  late VdoPlayerController _controller;

  List<double> _playbackSpeedList = [];
  List<SubtitleTrack> _subtitleTracksList = [];
  List<VideoTrack> _videoTracksList = [];

  final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);
  final ValueNotifier<bool> _showControls = ValueNotifier(false);
  final ValueNotifier<String> _currentDurationString = ValueNotifier("");
  final ValueNotifier<double> _currentPosition = ValueNotifier(0);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<VdoError?> _vdoError = ValueNotifier(null);
  final ValueNotifier<bool> _isEnded = ValueNotifier(false);

  final ValueNotifier<VdoPlayerValue?> vdoPlayerValueNotifier =
      ValueNotifier(null);

  Timer? _showControlsTimer;

  bool isSeeking = false;

  VdoPlayerService(
    this.embedInfo, {
    this.primaryColor = Colors.white,
    this.onSecondaryColor = Colors.white38,
    this.secondaryColor,
    this.onPrimaryColor,
  });

  /// Sets the controller, initializes the video to play and
  Future<void> onPlayerCreated(VdoPlayerController controller) async {
    _controller = controller;
    _initShowControls();

    _controller.addListener(_vdoChangeListener);
  }

  /// Listens and updates the variables as and when changed
  void _vdoChangeListener() {
    _isLoading.value = value.isBuffering || value.isLoading;
    vdoPlayerValueNotifier.value = value;

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
    _currentDurationString.value = convertSecondsToDuration(
      _currentPosition.value.toString(),
    );
    _isPlaying.value = value.isPlaying;
    _vdoError.value = value.vdoError;
    _isEnded.value = value.isEnded;
    if (value.isEnded) _showControls.value = true;
  }

  /// Toggles to full screen or portrait.
  void toggleFullScreen({bool shouldChangeOrientation = true}) {
    _isFullScreen.value = !isFullScreen;
    _changeOrientation();
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
    controller.stop();
    controller.dispose();
  }

  /// Toggles play or pause.
  void playPause() {
    if (_isPlaying.value) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  /// Forwards 10 seconds of the video.
  void forward() {
    final Duration seekValue = value.position + const Duration(seconds: 10);
    controller.seek(seekValue);
  }

  /// Rewinds 10 seconds of the video.
  void rewind() {
    final Duration seekValue = value.position - const Duration(seconds: 10);
    controller.seek(seekValue);
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

  /// Change the current video position.
  void changePosition(double position) {
    controller.seek(Duration(seconds: position.toInt()));
    _currentPosition.value = position;
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

  /// Reloads the video
  void reload() {
    controller.load(embedInfo);
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
      track.language ?? VdoStringConstants.disableSubtitles;

  /// Returns whether the given subtitle is selected or not.
  bool isSubtitleSelected(SubtitleTrack track) {
    if (track.language == null) {
      return value.subtitleTrack == null;
    }
    return value.subtitleTrack == track;
  }

  /// Returns the display string for speed.
  String getSpeedDisplayText(double speedValue) {
    if (speedValue == 1.0) return VdoStringConstants.normal;
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
    final String messagePrefix =
        "${VdoStringConstants.error}: ${vdoError.code} -";
    switch (vdoError.code) {
      case 2013:
      case 2018:
        return "$messagePrefix ${VdoStringConstants.otpExpiredError}";
      case 4101:
        return "$messagePrefix ${VdoStringConstants.invalidVideoParamentersError}";
      case 4102:
        return "$messagePrefix ${VdoStringConstants.offlineVideoNotFoundError}";
      case 5110:
      case 5124:
      case 5130:
        return "$messagePrefix ${VdoStringConstants.checkYourInternetError}";
      case 5113:
      case 5123:
      case 5133:
      case 5152:
        return "$messagePrefix ${VdoStringConstants.temporaryServiceError}";
      case 5151:
        return "$messagePrefix ${VdoStringConstants.networkError}";
      case 5160:
      case 5161:
        return "$messagePrefix ${VdoStringConstants.downloadedFiledDeletedError}";
      case 6101:
      case 6120:
      case 6122:
        return "$messagePrefix ${VdoStringConstants.decodingError}";
      case 6102:
        return "$messagePrefix ${VdoStringConstants.offlineVideoFailedError} ";
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
        return "$messagePrefix ${VdoStringConstants.phoneNotCompatibleError} ";
      case 6187:
        return "$messagePrefix ${VdoStringConstants.rentalLicenseExpiredError}";
      default:
        return "${VdoStringConstants.anErrorOccured}: ${vdoError.code} ${VdoStringConstants.tapToRetry}";
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
      convertSecondsToDuration(value.duration.inSeconds.toString());

  // List<double> get playbackSpeedList => _playbackSpeedList;
  List<double> get playbackSpeedList => value.playbackSpeedOptions;
  // List<VideoTrack> get videoTracks => _videoTracksList;
  List<VideoTrack> get videoTracks => value.videoTracks;
  // List<SubtitleTrack> get subtitleTracks {
  //   final List<SubtitleTrack> tracks = List.from(_subtitleTracksList);
  //   if (tracks.isEmpty) return [];
  //   tracks.insert(0, const SubtitleTrack(id: -1));
  //   return tracks;
  // }
  List<SubtitleTrack> get subtitleTracks {
    final List<SubtitleTrack> tracks = List.from(value.subtitleTracks);
    if (tracks.isEmpty) return [];
    tracks.insert(0, const SubtitleTrack(id: -1));
    return tracks;
  }

  bool get hasSpeed => playbackSpeedList.length > 1;
  bool get hasVideoQuality => videoTracks.length > 1;
  bool get hasSubtitles => subtitleTracks.isNotEmpty;

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

/// String Constants for the [CustomVdoPlayerView]
class VdoStringConstants {
  static const String anErrorOccured = "An error occurred:";
  static const String tapToRetry = "Tap to retry";
  static const String selectSubtitles = "Select Subtitles";
  static const String disableSubtitles = "Disable Subtitles";
  static const String selectPlaybackSpeed = "Select Playback Speed";
  static const String normal = "Normal";
  static const String selectVideoQuality = "Select Video Quality";
  static const String error = "Error";

  /// ********************** Error Strings for code *********************/
  static const String otpExpiredError =
      "OTP is expired or invalid. Please go back, and start playback again.";
  static const String invalidVideoParamentersError =
      "Invalid video parameters. Please contact the app developer.";
  static const String offlineVideoNotFoundError =
      "Offline video not found. Please make sure the video was downloaded successfully and not deleted.";
  static const String checkYourInternetError =
      "Please check your internet connection and try restarting the app.";
  static const String temporaryServiceError =
      "Temporary service error. This should automatically resolve quickly. Please try playback again.";
  static const String networkError =
      "Network error, possibly with your local ISP. Please try after some time.";
  static const String downloadedFiledDeletedError =
      "Downloaded media files have been accidentally deleted by some other app in your mobile. Kindly download the video again and do not use cleaner apps.";
  static const String decodingError =
      "Error decoding video. Kindly try restarting the phone and app.";
  static const String offlineVideoFailedError =
      "Offline video download is not yet complete or it failed. Please make sure it is successfully downloaded.";
  static const String phoneNotCompatibleError =
      "Phone is not compatible for secure playback. Kindly update your OS, restart the phone and app. If still not corrected, factory reset can be tried if possible.";
  static const String rentalLicenseExpiredError =
      "Rental license for downloaded video has expired. Kindly download again";
}

String convertSecondsToDuration(String duration) {
  double videoLength = double.parse(duration);
  if (videoLength > 3600) {
    final String hours =
        (videoLength / 3600).truncate().toString().padLeft(2, '0');
    videoLength %= 3600;
    final String minutes =
        (videoLength / 60).truncate().toString().padLeft(2, '0');
    videoLength %= 60;
    final String seconds = videoLength.truncate().toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  } else if (videoLength > 60) {
    final String minutes =
        (videoLength / 60).truncate().toString().padLeft(2, '0');
    videoLength %= 60;
    final String seconds = videoLength.truncate().toString().padLeft(2, '0');
    return "$minutes:$seconds";
  } else {
    final String seconds = videoLength.truncate().toString().padLeft(2, '0');
    return "00:$seconds";
  }
}
