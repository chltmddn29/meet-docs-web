class Meeting {
  final int meetingId;
  final String title;
  final String status;
  final DateTime createdAt;
  final int? duration;
  final List<AgendaItem> agendaItems;

  Meeting({
    required this.meetingId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.duration,
    this.agendaItems = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      meetingId: json['meeting_id'],
      title: json['title'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      duration: json['duration'],
      agendaItems:
          (json['agenda_items'] as List<dynamic>?)
              ?.map((e) => AgendaItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get formattedDate =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
}

class AgendaItem {
  final int? itemId;
  final String agenda;
  final int order;
  final String? content;
  final String? decision;
  final List<String> actionItems;

  AgendaItem({
    this.itemId,
    required this.agenda,
    required this.order,
    this.content,
    this.decision,
    this.actionItems = const [],
  });

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    final rawActions = json['action_items'];
    return AgendaItem(
      itemId: json['item_id'],
      agenda: json['agenda'] ?? '',
      order: json['order'] ?? 0,
      content: json['content'],
      decision: json['decision'],
      actionItems: rawActions is List ? List<String>.from(rawActions) : [],
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
