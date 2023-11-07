// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoDetailResponse _$VideoDetailResponseFromJson(Map<String, dynamic> json) =>
    VideoDetailResponse(
      json['title'] as String?,
      (json['chapters'] as List<dynamic>?)
              ?.map((e) => VideoChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      (json['captions'] as List<dynamic>?)
              ?.map((e) => Captions.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$VideoDetailResponseToJson(
        VideoDetailResponse instance) =>
    <String, dynamic>{
      'title': instance.title,
      'captions': instance.captions,
      'chapters': instance.chapters,
    };

Captions _$CaptionsFromJson(Map<String, dynamic> json) => Captions(
      captionName: json['captionName'] as String?,
      label: json['label'] as String?,
      lang: json['lang'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$CaptionsToJson(Captions instance) => <String, dynamic>{
      'captionName': instance.captionName,
      'label': instance.label,
      'lang': instance.lang,
      'url': instance.url,
    };

SubTitlesData _$SubTitlesDataFromJson(Map<String, dynamic> json) =>
    SubTitlesData(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$SubTitlesDataToJson(SubTitlesData instance) =>
    <String, dynamic>{
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'text': instance.text,
    };
