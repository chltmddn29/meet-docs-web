class FormatTemplate {
  final int formatTemplateId;
  final String name;
  final String content; // 목록에선 미리보기(200자), 상세에선 전체
  final String? sourceFilename;
  final DateTime? createdAt;

  FormatTemplate({
    required this.formatTemplateId,
    required this.name,
    this.content = '',
    this.sourceFilename,
    this.createdAt,
  });

  factory FormatTemplate.fromJson(Map<String, dynamic> json) {
    return FormatTemplate(
      formatTemplateId: json['format_template_id'],
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      sourceFilename: json['source_filename'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
