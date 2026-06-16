class ApiConstants {
  static const String baseUrl = 'https://meet-docs-service-server.onrender.com';

  // meetings
  static const String meetings = '/api/meetings';
  static String meeting(int id) => '/api/meetings/$id';
  static String uploadAudio(int id) => '/api/meetings/$id/upload-audio';
  static String processAudio(int id) => '/api/meetings/$id/process';
  static String analyzeMeeting(int id) => '/api/meetings/$id/analyze';
  static String saveMarkdown(int id) => '/api/meetings/$id/save-markdown';
  static String savePlatform(int id, String platform) =>
      '/api/meetings/$id/save-$platform';

  // download (full URL — opened directly in browser)
  static String _dl(int id) => '$baseUrl/api/meetings/$id';
  static String downloadPdf(int id) => '${_dl(id)}/download-pdf';
  static String downloadDocx(int id) => '${_dl(id)}/download-docx';
  static String downloadMarkdown(int id) => '${_dl(id)}/download-markdown';

  // audio
  static const String audioFiles = '/api/audio-files';
  static String deleteAudio(int id) => '/api/audio-files/$id';

  // templates
  static const String templates = '/api/templates';
  static String template(int id) => '/api/templates/$id';
}
