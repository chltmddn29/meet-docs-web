import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/template_model.dart';
import '../../meeting/provider/meeting_provider.dart';
import '../../../core/constants/api_constants.dart';

// 템플릿 목록
final templatesProvider = FutureProvider<List<Template>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.templates);
  return (response.data as List).map((e) => Template.fromJson(e)).toList();
});

// 단일 템플릿 상세 (agenda 화면에서 불러올 때 사용)
final templateDetailProvider = FutureProvider.family<Template, int>((
  ref,
  templateId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.template(templateId));
  return Template.fromJson(response.data);
});

// 템플릿 생성
final createTemplateProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (
    String name,
    String? description,
    List<String> agendaItems,
    List<String> participants,
  ) async {
    final response = await dio.post(
      ApiConstants.templates,
      data: {
        'name': name,
        'description': description,
        'agenda_items': agendaItems,
        'participants': participants,
      },
    );
    return Template.fromJson(response.data);
  };
});

// 템플릿 삭제
final deleteTemplateProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int templateId) async {
    await dio.delete(ApiConstants.template(templateId));
  };
});
