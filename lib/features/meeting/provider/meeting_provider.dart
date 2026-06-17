import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/meeting_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

final dioProvider = Provider((ref) => DioClient().dio);

final meetingsProvider = FutureProvider<List<Meeting>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.meetings);
  return (response.data as List).map((e) => Meeting.fromJson(e)).toList();
});

final meetingDetailProvider = FutureProvider.family<Meeting, int>((
  ref,
  meetingId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.meeting(meetingId));
  return Meeting.fromJson(response.data);
});

final createMeetingProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (String title, List<String> agenda, List<String> participants) async {
    final response = await dio.post(
      ApiConstants.meetings,
      data: {'title': title, 'agenda': agenda, 'participants': participants},
    );
    return Meeting.fromJson(response.data);
  };
});

final audioFilesProvider = FutureProvider<List<AudioFile>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.audioFiles);
  return (response.data as List).map((e) => AudioFile.fromJson(e)).toList();
});

final savePlatformProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int meetingId, String platform) async {
    final response = await dio.post(
      ApiConstants.savePlatform(meetingId, platform),
    );
    return response.data;
  };
});

final previewProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  meetingId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/api/meetings/$meetingId/preview');
  return response.data as Map<String, dynamic>;
});

final updateRawTextProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int meetingId, String rawText) async {
    final response = await dio.put(
      ApiConstants.updateRawText(meetingId),
      data: {'raw_text': rawText},
    );
    return response.data;
  };
});

// 할 일 모아보기 — 전체 회의의 할 일/한 일 집계
final todosProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.todos);
  return response.data as Map<String, dynamic>;
});

// 회의 삭제
final deleteMeetingProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int meetingId) async {
    await dio.delete(ApiConstants.deleteMeeting(meetingId));
  };
});
