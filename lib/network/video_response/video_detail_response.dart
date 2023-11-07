// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vdocipher_flutter_v3/models/video_chapter/video_chapter.dart';

part 'video_detail_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VideoDetailResponse {
  final String? title;
  @JsonKey(defaultValue: [])
  List<Captions>? captions;
  @JsonKey(defaultValue: [])
  final List<VideoChapter>? chapters;

  VideoDetailResponse(this.title, this.chapters, this.captions);

  factory VideoDetailResponse.fromJson(Map<String, dynamic> map) =>
      _$VideoDetailResponseFromJson(map);
  Map<String, dynamic> toJson() => _$VideoDetailResponseToJson(this);
}

@JsonSerializable()
class Captions {
  String? captionName;
  String? label;
  String? lang;
  String? url;
  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: [])
  List<SubTitlesData> subtitles = [];
  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: [])
  ValueNotifier<List<SubTitlesData>> searchSubTitle = ValueNotifier([]);

  Captions({
    this.captionName,
    this.label,
    this.lang,
    this.url,
  });

  factory Captions.fromJson(Map<String, dynamic> map) =>
      _$CaptionsFromJson(map);
  Map<String, dynamic> toJson() => _$CaptionsToJson(this);
}

@JsonSerializable()
class SubTitlesData {
  String startTime;
  String endTime;
  String text;
  SubTitlesData({
    required this.startTime,
    required this.endTime,
    required this.text,
  });
  factory SubTitlesData.fromJson(Map<String, dynamic> map) =>
      _$SubTitlesDataFromJson(map);
  Map<String, dynamic> toJson() => _$SubTitlesDataToJson(this);
}
