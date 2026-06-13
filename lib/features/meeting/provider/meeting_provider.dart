import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../model/meeting_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

final dioProvider = Provider((ref) => DioClient().dio);

// 회의 목록 Provider
final meetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.meetings);
  return (response.data as List).map((e) => Meeting.fromJson(e)).toList();
});

// 특정 회의 Provider
final meetingDetailProvider = FutureProvider.family<Meeting, int>((
  ref,
  meetingId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.meeting(meetingId));
  return Meeting.fromJson(response.data);
});

// 회의 생성 Provider
final createMeetingProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (String title, List<String> agenda) async {
    final response = await dio.post(
      ApiConstants.meetings,
      data: {'title': title, 'agenda': agenda},
    );
    return Meeting.fromJson(response.data);
  };
});

// 음성 파일 목록 Provider
final audioFilesProvider = FutureProvider<List<AudioFile>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.audioFiles);
  return (response.data as List).map((e) => AudioFile.fromJson(e)).toList();
});
