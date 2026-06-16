class Template {
  final int templateId;
  final String name;
  final String? description;
  final List<String> agendaItems;
  final String? participants;
  final DateTime? createdAt;

  Template({
    required this.templateId,
    required this.name,
    this.description,
    this.agendaItems = const [],
    this.participants,
    this.createdAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    List<String> agendas = [];
    if (json['agenda_items'] is List) {
      agendas = (json['agenda_items'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Template(
      templateId: json['template_id'],
      name: json['name'] ?? '',
      description: json['description'],
      agendaItems: agendas,
      participants: json['participants'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  // 쉼표로 구분된 참석자 문자열 → 리스트
  List<String> get participantList {
    if (participants == null || participants!.trim().isEmpty) return [];
    return participants!
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}
