class ApiConstants {
  static const String baseUrl = 'https://choiseungwoo-meet-docs.hf.space';

  // meetings
  static const String meetings = '/api/meetings';
  static String meeting(int id) => '/api/meetings/$id';
  static String deleteMeeting(int id) => '/api/meetings/$id';
  static String uploadAudio(int id) => '/api/meetings/$id/upload-audio';
  static String processAudio(int id) => '/api/meetings/$id/process';
  // 변환 진행 상태 폴링 (긴 회의는 백그라운드 변환 → 완료까지 주기적으로 확인)
  static String processStatus(int id) => '/api/meetings/$id/process-status';
  static String analyzeMeeting(int id) => '/api/meetings/$id/analyze';
  static String saveMarkdown(int id) => '/api/meetings/$id/save-markdown';
  static String savePlatform(int id, String platform) =>
      '/api/meetings/$id/save-$platform';

  // download (full URL — opened directly in browser)
  static String _dl(int id) => '$baseUrl/api/meetings/$id';
  static String downloadPdf(int id) => '${_dl(id)}/download-pdf';
  static String downloadDocx(int id) => '${_dl(id)}/download-docx';
  static String downloadMarkdown(int id) => '${_dl(id)}/download-markdown';
  static String downloadHwpx(int id) => '${_dl(id)}/download-hwpx';

  // audio
  static const String audioFiles = '/api/audio-files';
  static String deleteAudio(int id) => '/api/audio-files/$id';
  // 고아 음성(회의 삭제됨)을 새 회의로 다시 생성할 때: 새 회의 생성+연결
  static String newMeetingFromAudio(int transcriptId) =>
      '/api/audio-files/$transcriptId/new-meeting';
  // 재생: 브라우저에서 직접 열어 재생(inline)
  static String downloadAudioFile(int id) =>
      '$baseUrl/api/audio-files/$id/download';
  // 다운로드: attachment 로 받기
  static String downloadAudioFileAttachment(int id) =>
      '$baseUrl/api/audio-files/$id/download?download=true';

  // templates
  static const String templates = '/api/templates';
  static String template(int id) => '/api/templates/$id';

  // raw text 편집 + 재분석
  static String updateRawText(int id) => '/api/meetings/$id/raw-text';

  // 할 일 모아보기
  static const String todos = '/api/todos';
  // 할 일 체크 토글
  static String toggleActionCheck(int itemId) =>
      '/api/agenda-items/$itemId/action-check';

  // format templates (서식 — 파일 업로드 기반)
  static const String formatTemplates = '/api/format-templates';
  static const String uploadFormatTemplate = '/api/format-templates/upload';
  static const String generateFormatted = '/api/format-templates/generate';
  static const String addExampleFormatTemplates = '/api/format-templates/examples';
  static String formatTemplate(int id) => '/api/format-templates/$id';
}
