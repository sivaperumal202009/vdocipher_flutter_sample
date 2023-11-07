import 'package:json_annotation/json_annotation.dart';

part 'video_chapter.g.dart';

@JsonSerializable()
class VideoChapter {
  final String id;
  final String title;
  final int startTime;

  VideoChapter(this.id, this.title, this.startTime);

  factory VideoChapter.fromJson(Map<String, dynamic> map) =>
      _$VideoChapterFromJson(map);
  Map<String, dynamic> toJson() => _$VideoChapterToJson(this);
}
