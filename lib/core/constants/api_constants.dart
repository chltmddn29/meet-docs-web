class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';

  // meetings
  static const String meetings = '/api/meetings';
  static String meeting(int id) => '/api/meetings/$id';
  static String uploadAudio(int id) => '/api/meetings/$id/upload-audio';
  static String processAudio(int id) => '/api/meetings/$id/process';
  static String analyzeMeeting(int id) => '/api/meetings/$id/analyze';
  static String saveMarkdown(int id) => '/api/meetings/$id/save-markdown';

  // audio
  static const String audioFiles = '/api/audio-files';
  static String deleteAudio(int id) => '/api/audio-files/$id';
}
