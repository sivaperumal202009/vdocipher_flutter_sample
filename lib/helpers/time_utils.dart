class TimeUtils {
  TimeUtils._();

  static String convertSecondsToDuration(String duration) {
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
}
