import 'package:dio/dio.dart';
import 'package:vdocipher_flutter_v3/network/dio_helper.dart';
import 'package:vdocipher_flutter_v3/network/http_urls.dart';
import 'package:vdocipher_flutter_v3/network/video_response/video_detail_response.dart';

class VideoRepository {
  VideoRepository._();

  static Future<VideoDetailResponse> getVideoDetail(String videoId) async {
    final String url = HttpUrls.videoDetailUrl(videoId);
    try {
      final Response response = await dio.get(url);
      return VideoDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      return VideoDetailResponse.fromJson(error.response?.data);
    }
  }

  static Future<List<SubTitlesData>> getSRT(String vttURL) async {
    try {
      final Response response = await dio.get(vttURL);
      const pattern =
          r'(\d+)\n(\d{2}:\d{2}:\d{2}\.\d+) --> (\d{2}:\d{2}:\d{2}\.\d+)\n(.*)';

      RegExp timeRegExp = RegExp(pattern);

      final lines = timeRegExp.allMatches(response.data.toString());

      final subTitles = lines.map((e) {
        return SubTitlesData.fromJson({
          "startTime": convertToSeconds(e.group(2)!),
          "endTime": convertToSeconds(e.group(3)!),
          "text": "${e.group(4)}",
        });
      }).toList();
      return subTitles;
    } on DioException {
      return [];
    }
  }

  static String convertToSeconds(String timeString) {
    List<String> timeParts = timeString.split(':');

    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    List<String> secondsParts = timeParts[2].split('.');
    int seconds = int.parse(secondsParts[0]);

    int totalSeconds = hours * 3600 + minutes * 60 + seconds;

    return totalSeconds.toString();
  }
}
