import 'package:dio/dio.dart';

/// Dio 예외/HTTP 상태코드를 사용자 친화적 한국어 메시지로 변환.
/// 모든 네트워크 호출의 catch 블록에서 공통으로 사용.
String friendlyError(Object e) {
  if (e is! DioException) return e.toString();

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '서버 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.\n'
          '(무료 서버는 첫 요청에 최대 1분 걸릴 수 있어요)';
    case DioExceptionType.connectionError:
      return '서버에 연결할 수 없어요. 인터넷 연결을 확인해주세요.';
    case DioExceptionType.cancel:
      return '요청이 취소되었어요.';
    default:
      break;
  }

  final code = e.response?.statusCode;
  final detail = _extractDetail(e.response?.data);
  switch (code) {
    case 400:
      return detail ?? '요청 내용이 올바르지 않아요.';
    case 404:
      return detail ?? '대상을 찾을 수 없어요 (서버 재시작으로 삭제됐을 수 있어요).';
    case 413:
      return detail ?? '파일이 너무 큽니다 (최대 25MB).';
    case 500:
      return detail ?? '서버 처리 중 오류가 발생했어요.';
    case 502:
      return detail ?? 'AI 처리 중 오류가 발생했어요. 다시 시도해주세요.';
    case 503:
      return detail ?? 'AI 서비스가 일시적으로 준비되지 않았어요.';
    default:
      return detail ?? e.message ?? '알 수 없는 오류가 발생했어요.';
  }
}

String? _extractDetail(dynamic data) {
  if (data is Map && data['detail'] != null) {
    return data['detail'].toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
