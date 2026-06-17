import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/format_template_model.dart';
import '../../meeting/provider/meeting_provider.dart';
import '../../../core/constants/api_constants.dart';

// 서식 템플릿 목록
final formatTemplatesProvider = FutureProvider<List<FormatTemplate>>((
  ref,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.formatTemplates);
  return (response.data as List)
      .map((e) => FormatTemplate.fromJson(e))
      .toList();
});

// 파일 업로드 → 서식 템플릿 생성
final uploadFormatTemplateProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await dio.post(
      ApiConstants.uploadFormatTemplate,
      data: formData,
    );
    return FormatTemplate.fromJson(response.data);
  };
});

// 서식 템플릿 삭제
final deleteFormatTemplateProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int id) async {
    await dio.delete(ApiConstants.formatTemplate(id));
  };
});

// 예시 서식 추가 (플레이스홀더 데모) → 추가된 개수 반환
final addExampleFormatTemplatesProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return () async {
    final response = await dio.post(ApiConstants.addExampleFormatTemplates);
    return (response.data['added'] ?? 0) as int;
  };
});

// 회의 원본을 서식대로 AI 생성 → 마크다운 반환
final generateFormattedProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int meetingId, int formatTemplateId) async {
    final response = await dio.post(
      ApiConstants.generateFormatted,
      data: {
        'meeting_id': meetingId,
        'format_template_id': formatTemplateId,
      },
    );
    return (response.data['formatted'] ?? '').toString();
  };
});
