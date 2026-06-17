class Meeting {
  final int meetingId;
  final String title;
  final String status;
  final DateTime createdAt;
  final int? duration;
  final String? participants;
  final String? rawText;
  final List<AgendaItem> agendaItems;

  Meeting({
    required this.meetingId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.duration,
    this.participants,
    this.rawText,
    this.agendaItems = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      meetingId: json['meeting_id'],
      title: json['title'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      duration: json['duration'],
      participants: json['participants'],
      rawText: json['raw_text'],
      agendaItems:
          (json['agenda_items'] as List<dynamic>?)
              ?.map((e) => AgendaItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get formattedDate {
    final local = createdAt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class AgendaItem {
  final int? itemId;
  final String agenda;
  final int order;
  final String? content;
  final List<String> discussions;
  final String? decision;
  final List<String> completedItems;
  final List<String> actionItems;

  AgendaItem({
    this.itemId,
    required this.agenda,
    required this.order,
    this.content,
    this.discussions = const [],
    this.decision,
    this.completedItems = const [],
    this.actionItems = const [],
  });

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      itemId: json['item_id'],
      agenda: json['agenda'] ?? '',
      order: json['order'] ?? 0,
      content: json['content'],
      discussions: _strList(json['discussions']),
      decision: json['decision'],
      completedItems: _strList(json['completed_items']),
      actionItems: _strList(json['action_items']),
    );
  }
}

class AudioFile {
  final int transcriptId;
  final int meetingId;
  final String audioFilePath;

  AudioFile({
    required this.transcriptId,
    required this.meetingId,
    required this.audioFilePath,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      transcriptId: json['transcript_id'],
      meetingId: json['meeting_id'],
      audioFilePath: json['audio_file_path'],
    );
  }

  String get filename => audioFilePath.split('/').last;
}
